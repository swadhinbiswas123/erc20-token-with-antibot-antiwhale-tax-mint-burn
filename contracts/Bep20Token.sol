// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ERC20Interface {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// The Cryptos Token Contract
contract Bep20Token is ERC20Interface , Ownable{
    string public name = "Bep20 Token";
    string public symbol = "BTN";
    uint256 public decimals = 18;
    uint256 public override totalSupply;
    uint256 public taxAmount;
    address public taxWallet;

    uint256 public  maxTxWallet;
    uint256 public  maxTxAmount;

    uint256 public timeForWallet;

    address public founder;
    mapping(address => uint256) public balances;
    // balances[0x1111...] = 100;

    // timestamps for wallets

    mapping (address => uint256) private timeStampWallets;

    mapping(address => mapping(address => uint256)) allowances;

    // allowed[0x111][0x222] = 100;

    constructor(uint256 _taxAmount, address _taxWallet, uint256 _maxTxWallet, uint256 _maxTxAmount, uint256 _timeForWallet) {
         totalSupply = 1800000 * 10 ** decimals;
        founder = msg.sender;
        taxAmount = _taxAmount;
        taxWallet = _taxWallet;
        balances[founder] = totalSupply;
        maxTxWallet = _maxTxWallet * 10 ** decimals;
        maxTxAmount = _maxTxAmount * 10 ** decimals;
        timeForWallet = _timeForWallet;
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function taxCalculator( uint256 _amount) public view returns(uint256){
        return taxAmount * _amount  / 100;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool success)
    {
        address owner = msg.sender;
        require(balances[owner] >= amount);
        require(amount > 0);

        _approve(owner, spender, amount);

        emit Approval(owner, spender, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allowances[tokenOwner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
     
            _approve(owner, spender, currentAllowance - subtractedValue);


        return true;
    }


    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool success)
    {
        address from = msg.sender;
        _transfer(from, to, amount);
        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool success) {

        address spender = msg.sender;
        _spendAllowance(from, spender, amount);

        _transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) virtual internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balances[from];
        uint256 toBalance = balances[to];
        require(toBalance + amount <= maxTxWallet, "Exceeds maximum wallet token amount");
        require(amount <= maxTxAmount, "TX Limit Exceeded");
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 txTaxAmount = taxCalculator(amount);

        uint256 remainder = amount - txTaxAmount;

        require(remainder + txTaxAmount == amount, "Tax calculation is not correct");

        if(timeStampWallets[to] == 0){
            balances[taxWallet] += txTaxAmount;
            balances[from] = fromBalance - remainder;
            balances[to] += remainder;

            timeStampWallets[to] = block.timestamp;

        }else if(timeStampWallets[to] > 0){
            require(block.timestamp - timeStampWallets[to] > timeForWallet, "Not allowed for more transaction");
            balances[taxWallet] += txTaxAmount;
            balances[from] = fromBalance - remainder;
            balances[to] += remainder;

            timeStampWallets[to] = block.timestamp;
        }

    
        emit Transfer(from, to, amount);

    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

            balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            totalSupply -= amount;

        emit Transfer(account, address(0), amount);

    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            balances[account] += amount;

        emit Transfer(address(0), account, amount);

    }


    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
                _approve(owner, spender, currentAllowance - amount);
        }
    }
}