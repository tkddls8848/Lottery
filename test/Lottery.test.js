const Lottery = artifacts.require('Lottery');
const assertRevert = require('./assertRevert');
const expectEvent = require('./expectEvent');

contract('Lottery', ([coinbase, user1, user2]) => {

    let lottery;
    let betAmount = 5000000000000000;
    let BLOCK_INTERVAL = 3;

    beforeEach( async() => {
        lottery = await Lottery.new();
        console.log('new lottery');
    });

    it('getValue test', async () => {
        let owner = await lottery.owner();
        let value = await lottery.getValue();
        assert.equal(value , 5);
        console.log(`owner : ${owner}`)
    });

    it('pot test', async () => {
        let pot = await lottery.getPot();
        assert.equal(pot, 0);
        console.log(`pot : ${pot}`);
    });

    describe('Bet', () => {
        //fail transaction
        it('bet money is not 0.005 ETH', async () => {
            await assertRevert(lottery.bet('0xab', {from : user1, value:4000000000000000}));
        })
        //success transaction
        it('success transaction', async () => {
            let reciept = await lottery.bet('0xab', {from : user1, value:5000000000000000});

            let potMoney = await lottery.getPot();
            assert.equal(potMoney, 0);

            let contractBalance = await web3.eth.getBalance(lottery.address);
            assert.equal(contractBalance, betAmount);

            let betInfo = await lottery.getBetInfo(0);
            assert.equal(betInfo.answerBlockNumber, await web3.eth.getBlockNumber() + BLOCK_INTERVAL);
            assert.equal(betInfo.betPerson, user1);
            assert.equal(betInfo.challenges, '0xab');
            
            await expectEvent.inLogs(reciept.logs, 'BET')
        })
    })

    describe.only('isMatch', () => {
        let answer = '0xf3048ff1242af31bedd9f462ebd14d49f43423ee9342b278cdd847cc78fdf0a9';
        it('get win when 2 character matches', async () => {
            let result = await lottery.isMatch('0xf3', answer);
            assert.equal(result, 0);
        });
        it('get draw when 1 character matches', async () => {
            let result = await lottery.isMatch('0x03', answer);
            assert.equal(result, 2);
            
            result = await lottery.isMatch('0xf0', answer);
            assert.equal(result, 2);
        });
        it('get lose when no character matches', async () => {
            let result = await lottery.isMatch('0x12', answer);
            assert.equal(result, 1);
        });
    })
});