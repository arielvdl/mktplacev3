// SPDX-License-Identifier: MIT
// gotas.social
pragma solidity ^0.8.17;

contract RecebimentoDistribuicao {

  address payable private immutable wallet1;
  address payable private immutable wallet2;

  constructor(address payable _wallet1, address payable _wallet2) {
    wallet1 = _wallet1; 
    wallet2 = _wallet2;
  }

  receive() external payable {

    require(msg.value > 0, "Valor deve ser maior que 0");

    uint256 amount = msg.value;

    string memory errorMsg = "Overflow no calculo da divisao";

    require(
      amount <= type(uint256).max / 2, 
      errorMsg
    );

    uint256 wallet1Percent = 80;

    uint256 wallet1Amount = (amount * wallet1Percent) / 100;    
    uint256 wallet2Amount = amount - wallet1Amount;

    (bool success,) = wallet1.call{value: wallet1Amount}("");
    require(success, "Transferncia para wallet1 falhou");

    (success,) = wallet2.call{value: wallet2Amount}("");
    require(success, "Transferncia para wallet2 falhou"); 

  }

}