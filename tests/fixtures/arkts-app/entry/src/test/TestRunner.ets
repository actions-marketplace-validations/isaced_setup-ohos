import abilityTest from './List.test';
import hypium from '@ohos/hypium';

export default function testsuite() {
  hypium.setLength(500);
  abilityTest();
}
