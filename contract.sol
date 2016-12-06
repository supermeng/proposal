pragma solidity ^0.4.2;

contract ChoiceCtrct{
    struct Choice{
        string detail;
        bool exists;
    }
    
    mapping (uint8 => Choice) choicesDict;
    uint8[] choices;
    uint8 cid;
    address owner;
    
    event addChoice(uint indexed cid, string description);
    event delChoice(uint indexed cid);
    
    function ChoiceCtrct(){
        owner = msg.sender;
    }
    
    function AddChoice(string description){
        if(owner != msg.sender) throw;
        choicesDict[cid] = Choice(description, true);
        choices.push(cid);
        addChoice(cid, description);
        cid ++;
    }
    
    function DelChoice(uint8 cid) {
        if(owner != msg.sender) throw;
        if(!choicesDict[cid].exists) throw;
        delete choicesDict[cid];
        delChoice(cid);
        for (uint i=0; i < choices.length; i++){
            if(cid == choices[i]){
                delete choices[cid];
                return ;
            }
        }
    }
    
    function ChoiceExists(uint8 cid) returns (bool){
        return choicesDict[cid].exists;
    }
    
}

contract Proposal{
    enum PropState{
        PROPOSING,
        VOTING,
        OVER
    }
    
    struct Voter{
        uint8 choice;
        bool exists;
    }
    
    mapping (address => Voter) voters;
    mapping (uint8 => uint) counter;
    
    ChoiceCtrct choice;
    uint256 ending;
    string detail;
    PropState state;
    address owner;
    
    event vote(address indexed user, uint8 choice);
    event newChoice(ChoiceCtrct indexed choice);
    event over(Proposal proposal);
    
    function Proposal(address _owner, string _detail){
        state = PropState.PROPOSING;
        owner = _owner;
        detail = _detail;
        choice = new ChoiceCtrct();
        newChoice(choice);
    }
    
    function AddChoice(string _detail){
        if(state != PropState.PROPOSING) throw;
        if(owner != msg.sender) throw;
        choice.AddChoice(_detail);
    }
    
    function DelChoice(uint8 _cid){
        if(state != PropState.PROPOSING) throw;
        if(owner != msg.sender) throw;
        choice.DelChoice(_cid);
    }
    
    function SubmitWithVoters(address[] _voters, uint256 _ending){
        Submit(_ending);
        AddVoters(_voters);
    }
    
    function Submit(uint256 _ending){
        if(msg.sender != owner) throw;
        if(state != PropState.PROPOSING) throw;
        if(_ending < now) throw;
        state = PropState.VOTING;
        ending = _ending;
    }
    
    function AddVoters(address[] _voters){
        if(state != PropState.VOTING) throw;
        if(owner != msg.sender) throw;
        for(uint i = 0; i< _voters.length; i++){
            voters[_voters[i]].exists = true;
        }
    }
    
    function Vote(uint8 _choice){
        if(IsOver()) throw;
        var voter = msg.sender;
        if(!voters[voter].exists ||
        voters[voter].choice != address(0) ||
        !(choice.ChoiceExists(_choice))) throw;
        voters[voter].choice = _choice;
        vote(voter, _choice);
    }
    
    function IsOver() returns (bool) {
        if(state == PropState.OVER) return true;
        if(ending < now) {
            state = PropState.OVER;
            over(this);
            return true;
        }
    }
}

contract Proposer{
    event newProposal(uint indexed pid, string detail, Proposal pro);
    uint pid;
    string detail;
    
    function Proposer(string _detail){
        pid = 0;
        detail = _detail;
    }
    
    function NewProposal(string _detail) returns (Proposal){
        var proposal = new Proposal(msg.sender, _detail);
        newProposal(pid, _detail, proposal);
        pid ++;
        return proposal;
    }
}

contract ProposeService{
    uint pid;
    event newProposer(uint indexed pid, string detail, Proposer proper);
    
    function NewProposer(string _detail) returns (Proposer){
        var p = new Proposer(_detail);
        newProposer(pid, _detail, p);
        pid++;
        return p;
    }
}
