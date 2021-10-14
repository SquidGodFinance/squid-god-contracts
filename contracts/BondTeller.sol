// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./interfaces/IERC20.sol";

// TODO(zx): These staking Interfaces are not consistent
interface IStaking {
    function stake( uint _amount, address _recipient, bool _rebasing, bool _claim ) external returns ( bool );
}

interface IgOHM {
    function balanceTo( uint _amount ) external view returns ( uint );
    function balanceFrom( uint _amount ) external view returns ( uint );
}

interface ITreasury {
    function mintRewards( address _to, uint _amount ) external;
}

contract BondTeller {

    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint;
    using SafeERC20 for IERC20;



    /* ========== EVENTS ========== */

    event Redeemed( address indexed bonder, uint payout );



    /* ========== MODIFIERS ========== */

    modifier onlyDepository() {
        require( msg.sender == depository, "Only depository" );
        _;
    }



    /* ========== STRUCTS ========== */

    // Info for bond holder
    struct Bond {
        address principal; // token used to pay for bond
        uint principalPaid; // amount of principal token paid for bond
        uint payout; // sOHM remaining to be paid. agnostic balance
        uint vested; // Block when vested
        uint created; // time bond was created
        uint redeemed; // time bond was redeemed
    }



    /* ========== STATE VARIABLES ========== */

    address depository; // contract where users deposit bonds
    address immutable staking; // contract to stake payout
    ITreasury immutable treasury; 
    IERC20 immutable OHM; 
    IERC20 immutable sOHM; // payment token
    IgOHM immutable gOHM;

    mapping( address => Bond[] ) public bonderInfo; // user data
    mapping( address => uint[] ) public indexesFor; // user bond indexes

    mapping( address => uint ) public FERs; // front end operator rewards
    uint public feReward;
    
    address public policy;



    /* ========== CONSTRUCTOR ========== */

    constructor( 
        address _depository, 
        address _staking, 
        address _treasury,
        address _OHM, 
        address _sOHM, 
        address _gOHM 
    ) {
        require( _depository != address(0) );
        depository = _depository;
        require( _staking != address(0) );
        staking = _staking;
        require( _treasury != address(0) );
        treasury = ITreasury( _treasury );
        require( _OHM != address(0) );
        OHM = IERC20( _OHM );
        require( _sOHM != address(0) );
        sOHM = IERC20( _sOHM );
        require( _gOHM != address(0) );
        gOHM = IgOHM( _gOHM );
    }



    /* ========== DEPOSITORY FUNCTIONS ========== */

    /**
     * @notice add new bond payout to user data
     * @param _bonder address
     * @param _principal address
     * @param _principalPaid uint
     * @param _payout uint
     * @param _expires uint
     * @param _feo address
     * @return index_ uint
     */
    function newBond( 
        address _bonder, 
        address _principal,
        uint _principalPaid,
        uint _payout, 
        uint _expires,
        address _feo
    ) external onlyDepository() returns ( uint index_ ) {
        treasury.mintRewards( address(this), _payout.add( feReward ) );

        OHM.approve( staking, _payout ); // approve staking payout

        IStaking( staking ).stake( _payout, address(this), true, true );

        FERs[ _feo ] = FERs[ _feo ].add( feReward ); // FE operator takes fee
        
        index_ = bonderInfo[ _bonder ].length;

        // store bond & stake payout
        bonderInfo[ _bonder ].push( Bond({ 
            principal: _principal,
            principalPaid: _principalPaid,
            payout: gOHM.balanceTo( _payout ),
            vested: _expires,
            created: block.timestamp,
            redeemed: 0
        } ) );
    }

    /* ========== INTERACTABLE FUNCTIONS ========== */

    /**
     *  @notice redeems all redeemable bonds
     *  @param _bonder address
     *  @return uint
     */
    function redeemAll( address _bonder, bool _update ) external returns ( uint ) {
        if( _update ) {
            updateIndexesFor( _bonder );
        }
        return redeem( _bonder, indexesFor[ _bonder ] );
    }

    /** 
     *  @notice redeem bond for user
     *  @param _bonder address
     *  @param _indexes calldata uint[]
     *  @return uint
     */ 
    function redeem( address _bonder, uint[] memory _indexes ) public returns ( uint ) {
        uint dues;
        for( uint i = 0; i < _indexes.length; i++ ) {
            Bond memory info = bonderInfo[ _bonder ][ _indexes[ i ] ];

            if ( pendingFor( _bonder, _indexes[ i ] ) != 0 ) {
                bonderInfo[ _bonder ][ _indexes[ i ] ].redeemed = block.timestamp; // mark as redeemed
                
                dues = dues.add( info.payout );
            }
        }

        dues = gOHM.balanceFrom( dues );

        emit Redeemed( _bonder, dues );
        pay( _bonder, dues );
        return dues;
    }



    /* ========== OWNABLE FUNCTIONS ========== */

    function setFEReward( uint reward ) external {
        require( msg.sender == policy, "Only policy" );

        feReward = reward;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     *  @notice send payout
     *  @param _amount uint
     */
    function pay( address _bonder, uint _amount ) internal {
        sOHM.transfer( _bonder, _amount );
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     *  @notice returns indexes of live bonds
     *  @param _bonder address
     */
    function updateIndexesFor( address _bonder ) public {
        Bond[] memory info = bonderInfo[ _bonder ];
        delete indexesFor[ _bonder ];
        for( uint i = 0; i < info.length; i++ ) {
            if( info[ i ].redeemed == 0 ) {
                indexesFor[ _bonder ].push( i );
            }
        }
    }

    // PAYOUT

    /**
     * @notice calculate amount of OHM available for claim for single bond
     * @param _bonder address
     * @param _index uint
     * @return uint
     */
    function pendingFor( address _bonder, uint _index ) public view returns ( uint ) {
        if ( bonderInfo[ _bonder ][ _index ].redeemed == 0 && percentVestedFor( _bonder, _index ) >= 1e9 ) {
            return bonderInfo[ _bonder ][ _index ].payout;
        }
        return 0;
    }
    
    /**
     * @notice calculate amount of OHM available for claim for array of bonds
     * @param _bonder address
     * @param _indexes uint[]
     * @return pendingPayout_ uint
     */
    function pendingForIndexes( 
        address _bonder, 
        uint[] memory _indexes 
    ) public view returns ( uint pendingPayout_ ) {
        for( uint i = 0; i < _indexes.length; i++ ) {
            pendingPayout_ = pendingPayout_.add( pendingFor( _bonder, i ) );
        }
        pendingPayout_ = gOHM.balanceFrom( pendingPayout_ );
    }

    /**
     *  @notice total pending on all bonds for bonder
     *  @param _bonder address
     *  @return uint
     */
    function totalPendingFor( address _bonder ) public view returns ( uint ) {
        return pendingForIndexes( _bonder, indexesFor[ _bonder ] );
    }


    // VESTING

    /**
     * @notice calculate how far into vesting a depositor is
     * @param _bonder address
     * @param _index uint
     * @return percentVested_ uint
     */
    function percentVestedFor( address _bonder, uint _index ) public view returns ( uint percentVested_ ) {
        Bond memory bond = bonderInfo[ _bonder ][ _index ];

        uint timeSince = block.timestamp.sub( bond.created );
        uint term = bond.vested.sub( bond.created );

        percentVested_ = timeSince.mul( 1e9 ).div( term );
    }
}