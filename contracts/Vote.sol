// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Vote {
    //state Variables
    address admin;
    uint256 campaignId;
    Campaign[] allCampaigns;


    //events
    event Voted(address indexed voter, uint256 indexed campaignId, uint256 indexed time);
    event VoterRegistered(address[] indexed voter, uint256 indexed time, uint256 indexed campaignId);
    event CampaignCreated(address indexed campaignCreator, uint256 indexed campaignId, uint256 indexed time);
    event CandidateRegistered(address indexed candidate, uint256 indexed campaignId, uint256 indexed time);
    event AdminChanged(address indexed newAdmin, address indexed oldAdmin, uint256 indexed time);
    event Joined(address indexed joiner, string indexed organization, uint256 indexed time );

    struct Join {
        address joinedAddresss; 
        string emailAddress;
        string firstname;
        string lastname;
        string organization;   
        //bool approved;
    }

    struct Campaign{
        address campaignCreator;
        string name;
        string campaignDescription;
        uint256 startTime;
        uint256 duration;
        uint voteCount;
        address[] candidate;
        address[] voter;
    }

    struct Candidate {
        address candidateAddress;
        string candidateName;
        uint256 campaignId;
        uint256 voteAccumulated;
        address[] candidateVoters;
    }

    constructor(){
       admin = msg.sender;
    }
    

    // modifiers
    modifier onlyAdmin(){
        require(msg.sender == admin, "NOTADMIN!!");
        _;
    }

    modifier creatorsAndAdmin(){
        require(joined[msg.sender] == true || msg.sender == admin, "NOT VOTER OR ADMIN!!");
        _;
    }

    modifier campaignIdcheck(uint256 _campaignId){
        require(campaigns[_campaignId].campaignCreator != address(0), "Inavlid Campaign Id");
        _;
    }



    //mappings
    mapping(uint256 => Campaign) private campaigns;
    mapping(address => mapping(uint256 => Candidate)) candidates;
    mapping(address => mapping(uint256 => bool)) candidateRegistered;
    mapping(address => mapping(uint256 => bool)) votersRegistered;
    mapping(address => Join) joins;
    mapping(address => bool) joined;
    mapping(address => uint256[]) private allUserCampaings;
    mapping(uint256 => address[]) private allCampaignVoters;
    mapping(address => mapping(uint256 => bool)) private hasVoted;

    /**
     * @dev function for users to join
     */
    function join(string memory _emailAddress, string memory _firstname, string memory _lastname, string memory _organization) public {
        require(joins[msg.sender].joinedAddresss == address(0), "Already Joined");
        joins[msg.sender] = Join(msg.sender, _emailAddress, _firstname, _lastname, _organization);
        joined[msg.sender] = true;
        emit Joined(msg.sender, _organization, block.timestamp);
    }

    /**
     * @dev function for creating campaign
     */
    function createCampaign(string memory _CampaingName, string memory _campaignDescription,uint256 _startTime, uint256 _duration) creatorsAndAdmin public{
        bytes memory strBytes = bytes(_CampaingName);
        require(strBytes.length > 0, "Invalid CampaingName");
        require(_duration > 0, "Invalid duration");

        uint256 userCampaignId = campaignId;
        uint256 campaignDuration = block.timestamp + _duration;
        uint256 campaignStartTime = block.timestamp + _startTime;
        address[] memory _candidate;
        address[] memory _voters;
        campaigns[userCampaignId] = Campaign(msg.sender, _CampaingName,_campaignDescription, campaignStartTime, campaignDuration, 0, _candidate, _voters);
        allUserCampaings[msg.sender].push(userCampaignId);
        campaignId ++;

        emit CampaignCreated(msg.sender, userCampaignId, block.timestamp);
    }
    
    /**
     * @dev function to register candidate for a campaign
     */
    function registerCandidate(address _candidate, string memory _name, uint256 _campaignId) public campaignIdcheck(_campaignId){
        require(campaigns[_campaignId].startTime > block.timestamp, "Registration period is over");
        require(campaigns[_campaignId].campaignCreator == msg.sender, "Not Creator");
        require(candidateRegistered[_candidate][_campaignId] == false, "Registered Candidate");
        address[] memory _voters;
        candidates[_candidate][_campaignId] = Candidate(_candidate, _name, _campaignId, 0, _voters);
        candidateRegistered[_candidate][_campaignId] = true;
        campaigns[_campaignId].candidate.push(_candidate);
        

        emit CandidateRegistered(_candidate, _campaignId, block.timestamp);
    }


    /**
     * @dev function for admin to approve 
     */
    function registerVoter(address[] memory _voters, uint256 _campaignId) external {
        require(campaigns[_campaignId].startTime > block.timestamp, "Registration period is over");
        require(campaigns[_campaignId].campaignCreator == msg.sender, "Not Creator");
        //require(votersRegistered[_voter][_campaignId] == false, "Registered Voters");

        Campaign storage campaign = campaigns[_campaignId];

        for (uint256 i = 0; i < _voters.length; i++) {
            campaign.voter.push(_voters[i]);
            votersRegistered[_voters[i]][_campaignId] = true;
        }

        emit VoterRegistered(_voters, block.timestamp, _campaignId);
    }
       
    /**
     * @dev function for registered voters to vote
     */
    function vote(uint256 _campaignId, address _candidate) public campaignIdcheck(_campaignId){
        require(votersRegistered[msg.sender][_campaignId] == true, "NOT REGISTERED VOTER");
        require(hasVoted[msg.sender][_campaignId] == false, "ALREADY VOTED!!");
        require(campaigns[_campaignId].duration > block.timestamp, "Voting period is over");
        
        campaigns[_campaignId].voteCount += 1;
        candidates[_candidate][_campaignId].voteAccumulated +=1;
        candidates[_candidate][_campaignId].candidateVoters.push(msg.sender);
        hasVoted[msg.sender][_campaignId] = true;
        allCampaignVoters[_campaignId].push(msg.sender);

        emit Voted(msg.sender, _campaignId, block.timestamp);
    }

    /**
     * @dev function to change admin
     */
    function changeAdmin(address _newAdmin) public onlyAdmin{
        admin = _newAdmin;

    emit AdminChanged(_newAdmin, msg.sender, block.timestamp);
    }

    /**
     * @dev function to return all registered voters
     */
    function getVoters(uint256 _campaignId) public view returns(address[] memory){
        return campaigns[_campaignId].voter;
    }
    
    /**
     * @dev function to get a campaign
     */
    function getCampaign(uint256 _campaignId) public view campaignIdcheck(_campaignId) returns(Campaign memory){
        return (campaigns[_campaignId]);
    }

    /**
     * @dev function to get all campaigns created by a user
     */
    function AllUserCampaigns(address _userAddress) public view creatorsAndAdmin returns(Campaign[] memory){
        uint256[] memory allUserCampaignIndex = allUserCampaings[_userAddress];
        Campaign[] memory userCampaign = new Campaign[](allUserCampaignIndex.length);
    
        for (uint256 i = 0; i < allUserCampaignIndex.length; i++) {
            uint256 campaignIndex = allUserCampaignIndex[i];
            require(campaignIndex < campaignId, "Invalid campaign index");
            userCampaign[i] = campaigns[campaignIndex];
        }
    
        return userCampaign; 
    }

    /**
     * @dev function to get all voters of a campaign
     */
    function AllCampaignVoters(uint256 _campaignId) public view campaignIdcheck(_campaignId) returns(address[] memory){
        return allCampaignVoters[_campaignId];
    }

    /**
     * @dev function to get all campaigns
     */
    function allCampaign() public view returns(Campaign[] memory){
        Campaign[] memory allCampaignList = new Campaign[](campaignId);

        for (uint256 i = 0; i < campaignId; i++) {
            allCampaignList[i] = campaigns[i];
        }

        return allCampaignList;
    }

    /**
     * @dev function to get all candidates of a campaign
     */
    function allCampaignCandidate(uint256 _campaignId) public view returns(address[] memory){
        return campaigns[_campaignId].candidate;
    }

    /**
     * @dev function to get vote count of a campaign
     */
    function campaignTotalVote(uint256 _campaignId) public view campaignIdcheck(_campaignId) returns(uint256){
        return campaigns[_campaignId].voteCount;
    }

    /**
     * @dev function to get candidate details
     */
    function getCandidate(uint256 _campaignId, address _candidate) public view campaignIdcheck(_campaignId) returns(Candidate memory){
        return candidates[_candidate][_campaignId];
    }

    /**
     * @dev function to get a candidate vote count
     */
    function getCandidateVote(uint256 _campaignId, address _candidate) public view campaignIdcheck(_campaignId) returns(uint256){
        return candidates[_candidate][_campaignId].voteAccumulated;
    }
    
    /**
     * @dev function to get campaign winner + vote count
     */
    function getCampaignWinner(uint256 _campaignId) public view campaignIdcheck(_campaignId) returns(address winner, uint256 voteCount){
        address[] memory allCandidates = allCampaignCandidate(_campaignId);
        uint256 highestVoteCount = 0;
        
        for (uint256 i = 0; i < allCandidates.length; i++) {
            address candidateAddress = allCandidates[i];
            uint256 candidateVoteCount = candidates[candidateAddress][_campaignId].voteAccumulated;
            
            if (candidateVoteCount > highestVoteCount) {
                highestVoteCount = candidateVoteCount;
                winner = candidateAddress;
            }
        }
        
        voteCount = highestVoteCount;
    }
}
