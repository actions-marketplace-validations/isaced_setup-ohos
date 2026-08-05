import { describe, expect, it } from '@ohos/hypium';
import { add } from '../main/ets/utils/MathUtil';

export default function abilityTest() {
  describe('MathUtilTest', () => {
    it('add_1_plus_2_equals_3', 0, () => {
      expect(add(1, 2)).assertEqual(3);
    });
    it('add_negative_numbers', 0, () => {
      expect(add(-1, 1)).assertEqual(0);
    });
  });
}
