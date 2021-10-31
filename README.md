# Squid God Smart Contracts

## Mainnet Contracts & Addresses

|Contract       | Address                                                                                                            | Notes   |
|:-------------:|:-------------------------------------------------------------------------------------------------------------------:|-------|
|SGT            |[0x141381f07Fa31432243113Cda2F617d5d255d39a](https://bscscan.com/address/0x141381f07Fa31432243113Cda2F617d5d255d39a)| Main Token Contract|
|GAME           |[0x23204498Cd1d50Fa56769153a9284168AD5A4B50](https://bscscan.com/address/0x23204498Cd1d50Fa56769153a9284168AD5A4B50)| Staked SGT|
|Treasury       |[0xA2B48Ad28c09cc64CcCf9eD73e1EfceD052877d5](https://bscscan.com/address/0xA2B48Ad28c09cc64CcCf9eD73e1EfceD052877d5)| Squid God Treasury holds all the assets        |
| Staking |[0xb82aC36e9dF3c700F12ECF552F240BF4D7B7a212](https://bscscan.com/address/0xb82aC36e9dF3c700F12ECF552F240BF4D7B7a212)| Main Staking contract responsible for calling rebase every 8 hours|
|StakingHelper  |[0xb833FF51d277065b1Fd2d729835c2302fc2Fe5D0](https://bscscan.com/address/0xb833FF51d277065b1Fd2d729835c2302fc2Fe5D0)| Helper Contract to Stake with 0 warmup |
|DAO            |[0xD45c0F6Fc5082e8D3FfB81df26F9d2C83a3bF01e](https://bscscan.com/address/0xD45c0F6Fc5082e8D3FfB81df26F9d2C83a3bF01e)|Storage Wallet for DAO under MS |
|Staking Warm Up|[0xdd06743C82c2D8cAD4e975487A8c02AC5FD9E1B5](https://bscscan.com/address/0xdd06743C82c2D8cAD4e975487A8c02AC5FD9E1B5)| Instructs the Staking contract when a user can claim sOHM |


**Bonds**
All LP bonds use the Bonding Calculator contract which is used to compute RFV. 

|Contract       | Address                                                                                                            | Notes   |
|:-------------:|:-------------------------------------------------------------------------------------------------------------------:|-------|
|Bond Calculator|[0x74672E25b881618130c8A9a25A3312acFc6A4162](https://bscscan.com/address/0x74672E25b881618130c8A9a25A3312acFc6A4162)| |
|USDT Bond|[0xBEFf88671cfa710FD0E13D36F743711E2a50fe81](https://bscscan.com/address/0xBEFf88671cfa710FD0E13D36F743711E2a50fe81)| Main bond managing serve mechanics for SGT/USDT|
|USDT/SGT LP Bond|[0xE1Ae9D2933Ff625B3449C947b377280Ba9906c20](https://bscscan.com/address/0xE1Ae9D2933Ff625B3449C947b377280Ba9906c20)| Manages mechanism for the protocol to buy back its own liquidity from the pair. |


