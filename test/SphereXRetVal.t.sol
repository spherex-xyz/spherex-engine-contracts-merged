import "forge-std/Test.sol";
// import {console} from "forge-std/Console.sol";
import {SphereXEngine} from "src/SphereXEngine.sol";
import {ProtectedERC1967Proxy} from "src/ProtectedProxies/ProtectedERC1967Proxy.sol";

contract RetValTestContract {
    uint256 counter = 0;

    function increment() external returns (uint256) {
        counter++;
        return counter;
    }

    function get() external returns (uint256) {
        return counter;
    }

    function getWithParameters(uint256 a, uint256 b) external returns (uint256) {
        return counter;
    }
}

contract SphereXRetValTest is Test {
    RetValTestContract test_contract;
    SphereXEngine engine;
    ProtectedERC1967Proxy proxy;
    bytes4[] sigs;
    address[] allowed_senders;

    function setUp() public {
        RetValTestContract test_contract_imp = new RetValTestContract();
        engine = new SphereXEngine();
        proxy = new ProtectedERC1967Proxy(address(test_contract_imp), bytes(""));
        test_contract = RetValTestContract(address(proxy));

        allowed_senders.push(address(test_contract));
        engine.addAllowedSender(allowed_senders);
        engine.configureRules(bytes8(uint64(16)));

        proxy.changeSphereXOperator(address(this));
        proxy.changeSphereXEngine(address(engine));

        sigs.push(RetValTestContract.increment.selector);
        sigs.push(RetValTestContract.get.selector);
        sigs.push(RetValTestContract.getWithParameters.selector);
        proxy.addProtectedFuncSigs(sigs);
    }

    function testNormalOperation() public {
        assertEq(0, test_contract.get());
        assertEq(1, test_contract.increment());
        assertEq(1, test_contract.get());
    }

    function _applyGetRetValConstant(SphereXEngine.RuleType ruleType, uint256 dependsOnDataIndex) internal {
        uint256 num = uint256(uint32(RetValTestContract.get.selector));
        engine.changeRetDataRule(num, ruleType, dependsOnDataIndex);
        num = uint256(uint32(RetValTestContract.getWithParameters.selector));
        engine.changeRetDataRule(num, ruleType, dependsOnDataIndex);
    }

    function testConstantRetValWorks() public {
        _applyGetRetValConstant(SphereXEngine.RuleType.NOT_CHANGED_THROUGH_TX, 0);
        assertEq(0, test_contract.get());
        assertEq(0, test_contract.get());
    }

    function testConstantRetValReverts() public {
        _applyGetRetValConstant(SphereXEngine.RuleType.NOT_CHANGED_THROUGH_TX, 0);
        assertEq(0, test_contract.get());
        assertEq(1, test_contract.increment());

        vm.expectRevert("SphereX error: ret data changed");
        test_contract.get();
    }

    function testConstantRetValDiffTxWorks() public {
        _applyGetRetValConstant(SphereXEngine.RuleType.NOT_CHANGED_THROUGH_TX, 0);
        assertEq(0, test_contract.get());
        assertEq(1, test_contract.increment());

        vm.roll(block.number + 1);
        assertEq(1, test_contract.get());
    }

    function testConstantRetValParameterizedWorks() public {
        _applyGetRetValConstant(SphereXEngine.RuleType.NOT_CHANGED_THROUGH_TX, 1);
        assertEq(0, test_contract.getWithParameters(0, 0));
        test_contract.increment();
        assertEq(1, test_contract.getWithParameters(1, 0));
    }

    function testConstantRetValParameterizedReverts() public {
        _applyGetRetValConstant(SphereXEngine.RuleType.NOT_CHANGED_THROUGH_TX, 1);
        assertEq(0, test_contract.getWithParameters(5, 0));
        test_contract.increment();

        vm.expectRevert("SphereX error: ret data changed");
        test_contract.getWithParameters(5, 1);
    }

    function testConstantRetValParameterizedDiffTxWorks() public {
        _applyGetRetValConstant(SphereXEngine.RuleType.NOT_CHANGED_THROUGH_TX, 1);
        assertEq(0, test_contract.getWithParameters(5, 0));
        test_contract.increment();

        vm.roll(block.number + 1);
        assertEq(1, test_contract.getWithParameters(5, 1));
    }

    function testDisableRetValRuleWorks() public {
        _applyGetRetValConstant(SphereXEngine.RuleType.NOT_CHANGED_THROUGH_TX, 0);
        assertEq(0, test_contract.get());
        assertEq(1, test_contract.increment());

        _applyGetRetValConstant(SphereXEngine.RuleType.DISABLED, 0);
        assertEq(1, test_contract.get());
    }
}
