// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SplitDeposit {
    address public targetWallet;
    address public owner;

    constructor(address _targetWallet) {
        require(_targetWallet != address(0), "Invalid target wallet address");
        targetWallet = _targetWallet;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function depositToken(address tokenAddress, uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than zero");
        IERC20 token = IERC20(tokenAddress);

        uint256 tenPercent = amount / 10;
        uint256 ninetyPercent = amount - tenPercent;

        // Transfer 10% to the target wallet
        require(token.transferFrom(msg.sender, targetWallet, tenPercent), "Transfer to target wallet failed");

        // The remaining 90% stays in the contract
        require(token.transferFrom(msg.sender, address(this), ninetyPercent), "Transfer to contract failed");
    }

    function withdrawToken(address tokenAddress, uint256 amount, address to) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(amount <= token.balanceOf(address(this)), "Insufficient contract balance");
        require(token.transfer(to, amount), "Token transfer failed");
    }

    receive() external payable {}
}
