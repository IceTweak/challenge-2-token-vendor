pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

error IncorrectTokensToBuyAmount();
error InsufficientAmountToWithdraw();
error EthSendTxFailed(bytes data);
error InsufficientAproveAmount(uint256 allowance, uint256 neededAmount);
error InsufficientAmountToSell();

contract Vendor is Ownable {

  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event PartiallySell(address seller, uint256 sellAmount, uint256 unsellAmount);
  event FullSell(address seller, uint256 sellAmount);

  YourToken public yourToken;
  uint256 public constant tokensPerEth = 100;

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:
  function buyTokens() public payable {
    uint256 tokensToBuy = msg.value * tokensPerEth;

    if (tokensToBuy == 0 ) {
      revert IncorrectTokensToBuyAmount();
    }
    yourToken.transfer(msg.sender, tokensToBuy);

    emit BuyTokens(msg.sender, msg.value, tokensToBuy);
  }

  // ToDo: create a withdraw() function that lets the owner withdraw ETH
  function withdraw() public onlyOwner {
    uint256 amount = address(this).balance;
    
    if (amount == 0) {
      revert InsufficientAmountToWithdraw();
    }

    // ether transfer via call
    (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
    if (!sent) {
      revert EthSendTxFailed(data);
    }

  }

  // ToDo: create a sellTokens(uint256 _amount) function:
  function sellTokens(uint256 _amount) public {
    if (_amount == 0) {
      revert InsufficientAmountToSell();
    }

    if (yourToken.balanceOf(msg.sender) < _amount) {
      revert InsufficientAmountToSell();
    }

    uint256 allowance = yourToken.allowance(msg.sender, address(this));
    if (allowance < _amount) {
      revert InsufficientAproveAmount(allowance, _amount);
    }

    uint256 sellAmount = address(this).balance * tokensPerEth;

    if (sellAmount < _amount) {
      uint256 unsellAmount = _amount - sellAmount;
    
      (bool sent, bytes memory data) = msg.sender.call{value: address(this).balance}("");
      if (!sent) {
        revert EthSendTxFailed(data);
      }

      yourToken.transferFrom(msg.sender, address(this), sellAmount);

      emit PartiallySell(msg.sender, sellAmount, unsellAmount);
    } else {
      uint256 etherAmount = _amount / tokensPerEth;

      (bool sent, bytes memory data) = msg.sender.call{value: etherAmount}("");
      if (!sent) {
        revert EthSendTxFailed(data);
      }

      yourToken.transferFrom(msg.sender, address(this), _amount);
      
      emit FullSell(msg.sender, _amount);
    }
  }
}
