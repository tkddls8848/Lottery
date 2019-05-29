const Lottery = artifacts.require('Lottery');

contract('Lottery', ([coinbase, user1, user2]) => {
    let lottery;
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
});