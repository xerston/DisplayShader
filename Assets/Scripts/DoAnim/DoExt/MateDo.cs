using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Tools.TimerEvent.DoAnim
{
    public static partial class ObjectDo
    {
        #region DoFade

        public static SingleAnim DoFade(this Material obj,
            string color_name, float target_value, float time,
            TimerType timer_type = TimerType.Fixed)
        {
            Color color = obj.GetColor(color_name);

            MotionData motion_data = new MotionData();
            motion_data.start.x = color.a;
            motion_data.offset.x = target_value - motion_data.start.x;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => { motion_data.start.x = obj.GetColor(color_name).a; };
            paras.GetData = (p) => {
                color.a = motion_data.start.x + motion_data.offset.x * p;
                obj.SetColor(color_name, color);
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }

        #endregion

        #region DoColor

        public static SingleAnim DoColor(this Material obj,
            string color_name, Vector3 target_value, float time,
            TimerType timer_type = TimerType.Fixed)
        {
            Color color = obj.GetColor(color_name);

            MotionData motion_data = new MotionData();
            V3CopyColor(ref motion_data.start, color);
            motion_data.offset = target_value - motion_data.start;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => {
                V3CopyColor(ref motion_data.start, obj.GetColor(color_name));
            };
            Vector3 temp;
            paras.GetData = (p) => {
                temp = motion_data.start + motion_data.offset * p;
                ColorCopyV3(ref color, ref temp);
                obj.SetColor(color_name, color);
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }

        #endregion
    }
}
