
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Uniswap.sol";

// interface IBPContract {

//     function protect(address sender, address receiver, uint256 amount) external;

// }

contract  Token is Context, ERC20 {
    mapping(address => uint256) private adminlist;
    mapping(address => uint256) private blacklist;

    address BUSD;
    address addressReceiver;
    address addressTreasury;
    address addressBurn;
    address addressDev;
    address addressDeposit;

    address public uniswapV2Pair;

    uint256 public sellFeeRate = 10;
    uint256 public taxThreshold = 2001;
    uint256 public buyFeeRate = 10;

    uint256 public transferRate = 0;
    uint256 public antiBot = 0;
    
    uint256 percentAmountWhale = 100;

    address private constant UNISWAP_V2_ROUTER =
        0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24;

    uint256 public burnRate = 0;
    uint256 public treasuryRate = 0;


    // IBPContract public bpContract;
    // bool public bpEnabled;
    // bool public bpDisabledForever;

    /* 
================================================================
                        CONSTRUCTOR
================================================================
 */

    constructor(address _BUSD, address _addressReceiver, address _addressTreasury, address _addressBurn, address _addressDeposit, address _addressDev)
        ERC20("FinEdU", "FIE")
    {
        _mint(msg.sender, 10**10 * 10**18);
        adminlist[msg.sender] = 1;

        BUSD = _BUSD;
        addressReceiver = _addressReceiver;
        addressTreasury = _addressTreasury;
        addressDev = _addressDev;
        addressDeposit = _addressDeposit;
        addressBurn = _addressBurn;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            UNISWAP_V2_ROUTER

        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), BUSD);
    }

    /*
===================================================
                    MODIFIER
===================================================
 */
    modifier onlyAdmin() {
        require(adminlist[_msgSender()] == 1, "OnlyAdmin");
        _;
    }

    modifier notGreaterThanTaxThreshold(uint256 rate) {
        require(rate < taxThreshold, "Max Tax threshold is 20%");
        _;
    }


    modifier isNotInBlackList(address account) {
        require(!checkBlackList(account), "Revert blacklist");
        _;
    }

    modifier isNotAddressZero(address account) {
        require(account != address(0), "ERC20: transfer from the zero address");
        _;
    }

    /*
===================================================
                CHECK FUNCTION
===================================================
 */
    function checkAdmin(address account) public view returns (bool) {
        return adminlist[account] > 0;
    }

    function checkBlackList(address account) public view returns (bool) {
        return blacklist[account] > 0;
    }

    function checkAntiBot() public view returns (bool) {
        return antiBot == 1 ? true : false;
    }

    /*
===================================================
                    BOT PREVENT
===================================================
 */

    // function setBPContract(address addr)
    //     public
    //     onlyOwner
    // {
    //     require(addr != address(0), "BP address cannot be 0x0");

    //     bpContract = IBPContract(addr);
    // }

    // function setBPEnabled(bool enabled)
    //     public
    //     onlyOwner
    // {
    //     bpEnabled = enabled;
    // }

    // function setBPDisableForever()
    //     public
    //     onlyOwner
    // {
    //     require(!bpDisabledForever, "Bot protection disabled");

    //     bpDisabledForever = true;
    // }

    // function _beforeTokenTransfer(address from, address to, uint256 amount)
    //     internal
    //     override
    // {
    //     if (bpEnabled && !bpDisabledForever) {
    //         bpContract.protect(from, to, amount);
    //     }

    //     super._beforeTokenTransfer(from, to, amount);

    // }

 /*
===================================================
                    SWAP FUNCTION
===================================================
 */

    // function swap(
    //     address _tokenIn,
    //     address _tokenOut,
    //     uint256 _amountIn,
    //     uint256 _amountOutMin,
    //     address _to
    // ) internal {
    //     super.transferFrom(msg.sender, address(this), _amountIn);
    //     super.approve(UNISWAP_V2_ROUTER, _amountIn);
    //     address[] memory path;
    //     if (_tokenIn == BUSD || _tokenOut == BUSD) {
    //         path = new address[](2);
    //         path[0] = _tokenIn;
    //         path[1] = _tokenOut;
    //     } else {
    //         path = new address[](3);
    //         path[0] = _tokenIn;
    //         path[1] = BUSD;
    //         path[2] = _tokenOut;
    //     }
    //     IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
    //         _amountIn,
    //         _amountOutMin,
    //         path,
    //         _to,
    //         block.timestamp
    //     );
    // }

    // function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) internal view returns (uint256) {
    //     address[] memory path;
    //     if (_tokenIn == BUSD || _tokenOut == BUSD) {
    //         path = new address[](2);
    //         path[0] = _tokenIn;
    //         path[1] = _tokenOut;
    //     } else {
    //         path = new address[](3);
    //         path[0] = _tokenIn;
    //         path[1] = BUSD;
    //         path[2] = _tokenOut;
    //     }
    //     uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
    //     return amountOutMins[path.length -1];  
    // }  

    /*
===================================================
            TRANSFER & FEE CALCULATION
===================================================
 */
    function _transfer (
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 feeRate = _feeCalculation(sender, recipient, amount);
        if (feeRate > 0) {
            uint256 _fee = (amount * feeRate) / 10000;
            uint256 _burnAmount = _fee * burnRate / 10000;
            uint256 _treasuryAmount = _fee * treasuryRate / 10000;
            uint256 _profitAmount = _fee - _burnAmount - _treasuryAmount;

            // uint256 _amountOutMin = getAmountOutMin(address(this), BUSD, _fee1);
            // swap(address(this), BUSD, _fee1, _amountOutMin, addressReceiver);
            super._transfer(sender, addressReceiver ,_profitAmount);
            super._transfer(sender, addressTreasury ,_treasuryAmount);
            super._transfer(sender, addressBurn ,_burnAmount);

            amount = amount - _fee;
        }
        

        super._transfer(sender, recipient, amount);
    }
    function _feeCalculation(
        address sender,
        address recipient,
        uint256 amount
    )
        internal view
        isNotAddressZero(sender)
        isNotAddressZero(recipient)
        returns (uint256)
    {
        uint256 feeRate = 0;

        if (checkAntiBot()) {
            require(checkAdmin(sender) || checkAdmin(recipient), "Anti Bot");
            feeRate = 0;
        } else {
            if (recipient == uniswapV2Pair) {
                if (checkAdmin(sender)) {
                    feeRate = 0;
                } else {
                    require(
                        amount <=
                            (this.balanceOf(uniswapV2Pair) *
                                percentAmountWhale) /
                                10000,
                        "Revert whale transaction"
                    );
                    feeRate = sellFeeRate;
                }
            } else if (sender == uniswapV2Pair) {
                require(!checkBlackList(recipient), "Revert blacklist");
                
                if (checkAdmin(recipient)) {
                    feeRate = 0;
                } else {
                    require(
                        amount <=
                            (this.balanceOf(uniswapV2Pair) *
                                percentAmountWhale) /
                                10000,
                        "Revert whale transaction"
                    );
                    
                    feeRate = buyFeeRate;
                    

                }
            } else {
                require(!checkBlackList(sender), "Revert blacklist");
                
                if (checkAdmin(sender)) {
                    feeRate = 0;
                } else {
                    feeRate = transferRate;
                }
            }
        }
        return feeRate;
    }
/*----------------------------------------------------------------
                            WITHDRAW
 -----------------------------------------------------------------*/
    function withdrawTokenForOwner(uint256 amount) public onlyAdmin {
        this.transfer(msg.sender, amount);
        emit WithDraw(amount);
    }

    function withdrawBUSDForOwner(address token_address, uint256 amount)
        public
        onlyAdmin
    {
        IERC20 busd = IERC20(token_address);
        busd.transfer(msg.sender, amount);
        emit WithDraw(amount);
    }
/*
===================================================
                        EVENT
===================================================
 */
    event ChangeBuyFeeRate(uint256 rate);
    event ChangeSellFeeRate(uint256 rate);
    event ChangeBurnRate(uint256 rate);
    event ChangeTreasuryRate(uint256 rate);
    event ChangeTransferRate(uint256 rate);
    event ChangePercentAmountWhale(uint256 rate);
    event ActivateAntiBot(uint256 status);
    event DeactivateAntiBot(uint256 status);
    event AddedAdmin(address account);
    event AddedBatchAdmin(address[] accounts);
    event RemovedAdmin(address account);
    event TransferStatus(address sender, address recipient, uint256 amount);
    event WithDraw(uint256 amount);
    /*
===================================================
                UPDATE FUNCTION
===================================================
 */
    function changeBuyFeeRate(uint256 rate) external notGreaterThanTaxThreshold(rate) onlyAdmin {
        
        buyFeeRate = rate;
        emit ChangeBuyFeeRate(buyFeeRate);
    }

    function changeBurnRate(uint256 rate) external onlyAdmin {
        burnRate = rate;
        emit ChangeBurnRate(burnRate);
    }

    function changeTreasuryRate(uint256 rate) external onlyAdmin {
        treasuryRate = rate;
        emit ChangeTreasuryRate(burnRate);
    }



    function changeSellFeeRate(uint256 rate)  notGreaterThanTaxThreshold(rate) external onlyAdmin {
        sellFeeRate = rate;
        emit ChangeSellFeeRate(sellFeeRate);

    }

    function changeTransferRate(uint256 rate) external  notGreaterThanTaxThreshold(rate) onlyAdmin {
        transferRate = rate;
        emit ChangeTransferRate(transferRate);
    }

    function changePercentAmountWhale(uint256 rate) external onlyAdmin {
        percentAmountWhale = rate;
        emit ChangePercentAmountWhale(sellFeeRate);
    }

     function checkBuyRate() external view returns (uint256) {
            return buyFeeRate;
        //return balance;
    }

    /*
===================================================
                CHANGE ANTIBOT STATUS
===================================================
 */

    function activateAntiBot() external onlyAdmin {
        antiBot = 1;
        emit ActivateAntiBot(antiBot);
    }

    function deactivateAntiBot() external onlyAdmin {
        antiBot = 0;
        emit DeactivateAntiBot(antiBot);
    }

    /*
===================================================
                    ADMINLIST
===================================================
 */
    function addToAdminlist(address account) external onlyAdmin {
        adminlist[account] = 1;
        emit AddedAdmin(account);
    }

    function addBatchToAdminlist(address[] memory accounts) external onlyAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            adminlist[accounts[i]] = 1;
        }
        emit AddedBatchAdmin(accounts);
    }

    function removeFromAdminlist(address account) external onlyAdmin {
        adminlist[account] = 0;
        emit RemovedAdmin(account);
    }

    /*
===================================================
                    BLACKLIST
===================================================
 */

    function addToBlacklist(address account) external onlyAdmin {
        blacklist[account] = 1;
        emit AddedAdmin(account);
    }

    function addBatchToBlacklist(address[] memory accounts) external onlyAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklist[accounts[i]] = 1;
        }
        emit AddedBatchAdmin(accounts);
    }

    function removeFromBlacklist(address account) external onlyAdmin {
        blacklist[account] = 0;
        emit RemovedAdmin(account);
    }
}
