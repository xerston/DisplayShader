using UnityEngine;
using UnityEngine.UI;

namespace Tools.TimerEvent.DoAnim
{
    public static partial class ObjectDo
    {
        #region DoFade

        public static SingleAnim DoFade(this Image obj,
            float target_value, float time, TimerType timer_type = TimerType.Fixed)
        {
            Color color = obj.color;

            MotionData motion_data = new MotionData();
            motion_data.start.x = color.a;
            motion_data.offset.x = target_value - motion_data.start.x;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => { motion_data.start.x = obj.color.a; };
            paras.GetData = (p) => {
                color.a = motion_data.start.x + motion_data.offset.x * p;
                obj.color = color;
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }

        #endregion

        #region DoColor

        public static SingleAnim DoColor(this Image obj,
            Vector3 target_value, float time, TimerType timer_type = TimerType.Fixed)
        {
            Color color = obj.color;

            MotionData motion_data = new MotionData();
            V3CopyColor(ref motion_data.start, color);
            motion_data.offset = target_value - motion_data.start;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => {
                V3CopyColor(ref motion_data.start, obj.color);
            };
            Vector3 temp;
            paras.GetData = (p) => {
                temp = motion_data.start + motion_data.offset * p;
                ColorCopyV3(ref color, ref temp);
                obj.color = color;
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }
        private static void V3CopyColor(ref Vector3 v3, Color color)
        {
            v3.x = color.r;
            v3.y = color.g;
            v3.z = color.b;
        }
        private static void ColorCopyV3(ref Color color, ref Vector3 v3)
        {
            color.r = v3.x;
            color.g = v3.y;
            color.b = v3.z;
        }

        #endregion
    }
}
