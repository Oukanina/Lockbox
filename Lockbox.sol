/**
 * Source Code first verified at https://etherscan.io on Wednesday, May 8, 2019
 (UTC) */

pragma solidity >=0.4.22 <0.6.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Lockbox {

    using SafeMath for uint;
    using SafeMath for uint256;

    uint private _lockID;
    uint private _boxID;

    struct Lock {
        uint ID;
        uint boxID;
        uint amount;
        bool isLock;
        address owner;
    }
    struct Box {
        uint ID;
        uint256 balance;
        address owner;
        uint lock;
        bool enable;
        mapping(address => uint256) allocation;
    }

    mapping(uint => Box) public boxIndex;
    mapping(uint => Lock) public lockIndex;

    constructor() public {
        _boxID = 1;
        _lockID = 1;
    }

    function createBox() public {
        Box memory _box = Box({ ID: _boxID, balance: 0, owner: msg.sender, lock: 1, enable: false });
        boxIndex[_boxID] = _box;
        _boxID++;
    }

    function enableBox(uint boxID) public {
        Box storage _box = boxIndex[boxID];

        if (_box.owner != msg.sender) {
            revert();
        }
        else {
            _box.enable = true;
        }
    }

    function setBoxAllocation(uint boxID, address person, uint256 reward) public {
        Box storage _box = boxIndex[boxID];

        if (_box.owner != msg.sender) {
            revert();
        }
        else if (_box.enable) {
            revert();
        }
        else if (isBoxLocked(boxID)) {
            revert();
        }
        else {
            _box.allocation[person] = reward;
        }
    }

    function addLock(uint boxID, uint256 amount, address person) public {
        Box storage _box = boxIndex[boxID];

        if (_box.owner != msg.sender) {
            revert();
        }
        else if(_box.enable) {
            revert();
        } else {
            Lock memory newLock = Lock({ ID: _lockID, boxID: _box.ID, amount: amount, isLock: false, owner: person });
            lockIndex[_lockID] = newLock;
            _lockID++;
        }
    }

    function lock(uint lockID) public payable {
        Lock storage _lock = lockIndex[lockID];
        Box storage _box = boxIndex[_lock.boxID];

        if (_lock.isLock == true) {
            revert();
        }
        else if (_lock.owner != msg.sender) {
            revert();
        }
        else if (!_box.enable) {
            revert();
        }
        else if (_lock.amount != msg.value) {
            revert();
        }
        else {
            _lock.isLock = true;
            _box.balance += msg.value;
            _box.lock += 1;
        }
    }

    function unLock(uint lockID) public {
        Lock storage _lock = lockIndex[lockID];
        Box storage _box = boxIndex[_lock.boxID];

        if (_lock.isLock == false) {
            revert();
        }
        else if (_lock.owner != msg.sender) {
            revert();
        }
        else {
            _lock.isLock = false;
            _box.lock -= 1;
        }
    }

    function isBoxLocked(uint boxID) public view returns (bool locked) {
        Box storage _box = boxIndex[boxID];
        return _box.lock > 1;
    }

    function withdraw(uint boxID) public {
        Box storage _box = boxIndex[boxID];
        uint256 amount = _box.allocation[msg.sender];

        if (isBoxLocked(boxID)) {
            revert();
        }
        else if (amount <= 0) {
            revert();
        }
        else if (_box.balance <= 0) {
            revert();
        }
        else if (_box.balance < amount) {
            revert();
        }
        else {
            _box.balance -= amount;
            msg.sender.transfer(amount);
        }
    }

    function isBoxEnable(uint boxID) public view returns (bool) {
        Box storage _box = boxIndex[boxID];
        return _box.enable;
    }

    function getReward(uint boxID, address addr) public view returns(uint256) {
        Box storage _box = boxIndex[boxID];
        return _box.allocation[addr];
    }
}