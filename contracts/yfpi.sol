    // ------------------------------------------------------------------------
    // MIT License
    // Copyright (c) 2020 Yearn Finance Passive Income
    //
    // Permission is hereby granted, free of charge, to any person obtaining a copy
    // of this software and associated documentation files (the "Software"), to deal
    // in the Software without restriction, including without limitation the rights
    // to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    // copies of the Software, and to permit persons to whom the Software is
    // furnished to do so, subject to the following conditions:
    //
    // The above copyright notice and this permission notice shall be included in all
    // copies or substantial portions of the Software.
    //
    // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    // IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    // FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    // AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    // LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    // OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    // SOFTWARE.
    // ------------------------------------------------------------------------    

pragma solidity ^0.5.13;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------*/
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes memory data
    ) public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;
    address payable public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// Preasale code included
// ----------------------------------------------------------------------------
contract MyToken is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 _totalSupply;
    uint256 public burnedToken_;
    bool public isRoundOneActive;
    bool public isRoundTwoActive;
    uint256 public PresaleToken;
    // token limit for presale two
    uint256 private TokenLimit;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "MYT";
        name = "MyToken Token";
        decimals = 18;
        _totalSupply = 30000 * 10**uint256(decimals);
        PresaleToken = 15000 * 10**uint256(decimals);
        TokenLimit = 6000 * 10**uint256(decimals);
        balances[owner] = _totalSupply - PresaleToken;
        isRoundOneActive = true;
        isRoundTwoActive = false;
        emit Transfer(address(0), owner, _totalSupply - PresaleToken);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint256) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens)
        public
        returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens)
        public
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(
        address spender,
        uint256 tokens,
        bytes memory data
    ) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(
            msg.sender,
            tokens,
            address(this),
            data
        );
        return true;
    }


    // ------------------------------------------------------------------------
    // tokens can be buy by either paying to contract address or paying at buyToken function
    // ------------------------------------------------------------------------    
    function() external payable {
      
        uint256 tokens;
         if(isRoundOneActive == true){
           tokens = msg.value * 36;
           require(tokens  <= (PresaleToken - TokenLimit));
        } else if(isRoundTwoActive ==true) {
            tokens = msg.value * 24;
            require(tokens <= PresaleToken);
        }
        else {
            require(isRoundOneActive == true || isRoundOneActive == true);
        }
        
        balances[msg.sender] += tokens;
        PresaleToken -= tokens;
        // sent to investor
        emit Transfer(address(this), msg.sender, tokens);
        // sent ETH to owner
        owner.transfer(msg.value);
    }

    // ------------------------------------------------------------------------
    // tokens can be buy by either paying to contract address or paying at buyToken function
    // ------------------------------------------------------------------------    
  function buyToken()
        public payable
        {
            uint256 tokens;
         if(isRoundOneActive == true){
           tokens = msg.value * 36;
           require(tokens  <= (PresaleToken - TokenLimit));
        } else if(isRoundTwoActive ==true) {
            tokens = msg.value * 24;
            require(tokens <= PresaleToken);
        }
        else {
            require(isRoundOneActive == true || isRoundOneActive == true);
        }
        require(tokens <= PresaleToken);
        balances[msg.sender] += tokens;
        PresaleToken -= tokens;
        // sent to investor
        emit Transfer(address(this), msg.sender, tokens);
        // sent ETH to owner
        owner.transfer(msg.value);
        }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


    // ------------------------------------------------------------------------
    // Owner acitvate or deactivate Presale Sround at any time
    // ------------------------------------------------------------------------
    function activateRound(int8 round)
        public onlyOwner
        returns (bool success)
    {
        if(round==1){
            isRoundOneActive = true;
            isRoundTwoActive = false;
            return true;
        } else if(round==2) {
            isRoundOneActive = false;
            isRoundTwoActive = true;
            return true;
        }
        else if(round==0){
            isRoundOneActive = false;
            isRoundTwoActive = false;
            return true;
        }
        return true;
    }


    // ------------------------------------------------------------------------
    // To close Presale and retrive all remaining token to owner's account
    // ------------------------------------------------------------------------

     function closePresale()
        public onlyOwner
        returns (bool success)
    {
        balances[msg.sender] += PresaleToken;
        PresaleToken -= PresaleToken;
        emit Transfer(address(this),msg.sender, PresaleToken);
        return true;
    }

    // ------------------------------------------------------------------------
    // TokenOwner can burn their tokens for tokenOwner's account
    // ------------------------------------------------------------------------

     function burn(uint256 amount) public returns (bool success){
        require(msg.sender != address(0), "ERC20: burn from the zero address");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        burnedToken_ += amount;
         return true;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally stucked ether
    // ------------------------------------------------------------------------
      function withdrawAll() public onlyOwner {
        msg.sender.transfer(address(this).balance);
        emit Transfer(address(this), msg.sender, address(this).balance);
    }
}
