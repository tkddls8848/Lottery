pragma solidity >=0.4.21 <0.6.0;

contract Lottery {

    struct BetInfo {
        uint256 answerBlockNumber;
        address payable betPerson;
        byte challenges;
    }

    uint256 private head;
    uint256 private tail;
    mapping(uint256=>BetInfo) private betInfoMap;

    address public owner;
    bool private mode; // false : test mode, true : real use
    bytes32 public answerForTest;

    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;
    uint256 constant internal BLOCK_INTERVAL = 3;
    uint256 constant internal BLOCK_LIMIT = 256;

    uint256 private pot;

    enum BlockStatus {BEHIND_BLOCK_LIMIT, ON_THE_BLOCK, OVER_THE_BLOCK, UNKNOWN_STATUS}
    enum BettingResult {WIN, LOSE, DRAW}

    event BET(uint256 index, address betPerson, uint256 amount, uint256 answerBlockNumber, byte challenges);

    constructor() public {
        owner = msg.sender;
    }

    function getPot() public view returns (uint256 potValue) {
        return pot;
    }

    /**
     * @dev 베팅을 한다. 유저는 0.005 ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자
     * @return 함수가 잘 수행되었는지 확인해는 bool 값
     */
    function bet(byte challenges) public payable returns (bool result) {
        require(msg.value == BET_AMOUNT, 'not enough ETH');
        require(pushBet(challenges), 'cant pushBet');
        emit BET(tail-1, msg.sender,msg.value, block.number+BLOCK_INTERVAL, challenges);

        return true;
    }

    /**distribute bet ETH by result */
    function distribute() public {
        uint256 flag;
        BetInfo memory b;
        BlockStatus currentStatus;
        BettingResult currentBettingResult;

        for(flag=head;flag<tail;flag++){
            b = betInfoMap[flag];
            currentStatus = getBlockStatus(b.answerBlockNumber);

            if(currentStatus == BlockStatus.BEHIND_BLOCK_LIMIT) {
                //refund
                //emit refund event
            } else if(currentStatus == BlockStatus.ON_THE_BLOCK) {
                currentBettingResult = isMatch(b.challenges, getAnswerBlockHash(b.answerBlockNumber));
                
                if (currentBettingResult == BettingResult.WIN) {
                    // transfer pot to better
                    //  pot = 0
                    // emit Win event
                } else if (currentBettingResult == BettingResult.LOSE) {
                    // transfer BET_AMOUNT to pot
                    // pot += BET_AMOUNT
                    //emit LOSE event
                } else if (currentBettingResult == BettingResult.DRAW) {
                    // transfer only BET_AMOUNT to better
                    // emit DRAW event
                    //
                }

            } else if(currentStatus == BlockStatus.OVER_THE_BLOCK) {
                break;
            }

            popBet(flag);
        }
    }

    function setAnswerForTest(bytes32 answer) public returns(bool result){
        require(msg.sender == owner, "Only for owner");
        this.answerForTest = answer;
        return true;
    }

    //hash값은 random하기에 테스트를 위해서 임의의 해시값을 이용하여 테스트하는 모드를 구현.
    function getAnswerBlockHash(bytes32 answerBlockHash) public returns (bool result) {
        return mode ? blockhash(answerBlockHash) : answerForTest;
    }

    function betAndDistribute(byte challenges) public payable returns (bool result){
        bet(challenges);
        distribute();
        return true;
    }

    /** check between challenge and hashnumber*/
    function isMatch(byte challenges, bytes32 answer) public pure returns (BettingResult) {

        byte c1 = challenges;
        byte c2 = challenges;

        c1 = c1 >> 4;    //0x0a
        c1 = c1 << 4;    //0xa0    

        c2 = c2 << 4;    //0xb0
        c2 = c2 >> 4;    //0x0b  

        byte a1 = answer[0];
        byte a2 = answer[0];    

        a1 = a1 >> 4;
        a1 = a1 << 4;  

        a2 = a2 << 4;
        a2 = a2 >> 4;      

        if(a1 == c1 && a2 == c2) {
            return BettingResult.WIN;
        } else if(a1 == c1 || a2 == c2) {
            return BettingResult.DRAW;
        }
        return BettingResult.LOSE;
    }

    /**
    BEHIND_BLOCK_LIMIT => refund
    ON_THE_BLOCK => bet
    OVER_THE_BLOCK=> cancel
     */
    function getBlockStatus(uint256 answerBlockNumber) public view returns (BlockStatus){
        if(answerBlockNumber < block.number - BLOCK_LIMIT) {
            return BlockStatus.BEHIND_BLOCK_LIMIT;
        } else if(answerBlockNumber >= block.number - BLOCK_LIMIT && answerBlockNumber < block.number) {
            return BlockStatus.ON_THE_BLOCK;
        } else if(answerBlockNumber >= block.number) {
            return BlockStatus.OVER_THE_BLOCK;
        }
        return BlockStatus.UNKNOWN_STATUS; // prevent unexpected error
    }

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address betPerson, byte challenges) {
        BetInfo memory b = betInfoMap[index];
        answerBlockNumber = b.answerBlockNumber;
        betPerson = b.betPerson;
        challenges = b.challenges;
    }

    // start bet queue
    function pushBet(byte challenges) internal returns (bool){
        BetInfo memory b;

        b.answerBlockNumber = block.number + BLOCK_INTERVAL;
        b.betPerson = msg.sender;
        b.challenges = challenges;

        betInfoMap[tail] = b;
        tail++;

        return true;
    }

    // end bet queue
    function popBet(uint256 index) public returns (bool){
        delete betInfoMap[index];
        
        return true;   
    }
}