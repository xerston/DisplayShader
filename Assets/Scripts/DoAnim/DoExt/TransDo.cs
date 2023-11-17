using UnityEngine;

namespace Tools.TimerEvent.DoAnim
{
    public static partial class ObjectDo
    {
        #region DoMove

        public static SingleAnim DoMove(this Transform obj,
            Vector3 target_value, float time, TimerType timer_type = TimerType.Fixed)
        {
            MotionData motion_data = new MotionData();
            motion_data.start = obj.position;
            motion_data.offset = target_value - motion_data.start;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => { motion_data.start = obj.position; };
            paras.GetData = (p) => {
                obj.position = motion_data.start + motion_data.offset * p;
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }
        public static SingleAnim DoLocalMove(this Transform obj,
            Vector3 target_value, float time, TimerType timer_type = TimerType.Fixed)
        {
            MotionData motion_data = new MotionData();
            motion_data.start = obj.localPosition;
            motion_data.offset = target_value - motion_data.start;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => { motion_data.start = obj.localPosition; };
            paras.GetData = (p) => {
                obj.localPosition = motion_data.start + motion_data.offset * p;
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }

        public static SingleAnim DoBezierMove(this Transform obj, Vector3 mid_pos,
            Vector3 target_value, float time, TimerType timer_type = TimerType.Fixed)
        {
            MotionData motion_data = new MotionData();
            motion_data.start = obj.position;
            motion_data.offset = target_value - motion_data.start;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => {
                Vector3 offset = obj.position - motion_data.start;
                mid_pos += offset;
                motion_data.start = obj.position;
            };
            paras.GetData = (p) => {
                obj.position = GetBezierPos(p, motion_data.start, mid_pos, motion_data.start + motion_data.offset);
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }
        private static Vector3 GetBezierPos(float p, Vector3 start, Vector3 mid, Vector3 end)
        {
            return (1 - p) * (1 - p) * start + 2 * p * (1 - p) * mid + p * p * end;
        }

        #endregion

        #region DoRotate

        public static SingleAnim DoRotate(this Transform obj,
            Vector3 target_value, float time, TimerType timer_type = TimerType.Fixed)
        {
            MotionData motion_data = new MotionData();
            motion_data.start = obj.eulerAngles;
            motion_data.offset = target_value - motion_data.start;
            LimitEulerIn180(ref motion_data.offset);

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => { motion_data.start = obj.eulerAngles; };
            paras.GetData = (p) => {
                obj.rotation = Quaternion.Euler(motion_data.start + motion_data.offset * p);
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }
        public static SingleAnim DoLocalRotate(this Transform obj,
            Vector3 target_value, float time, TimerType timer_type = TimerType.Fixed)
        {
            MotionData motion_data = new MotionData();
            motion_data.start = obj.localEulerAngles;
            motion_data.offset = target_value - motion_data.start;
            LimitEulerIn180(ref motion_data.offset);

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => { motion_data.start = obj.localEulerAngles; };
            paras.GetData = (p) => {
                obj.localRotation = Quaternion.Euler(motion_data.start + motion_data.offset * p);
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }
        private static void LimitEulerIn180(ref Vector3 euler)
        {
            euler.x = euler.x % 360;
            if (Mathf.Abs(euler.x) > 180f)
            {
                if (euler.x < 0)
                {
                    euler.x += 360f;
                }
                else
                {
                    euler.x -= 360f;
                }
            }
            euler.y = euler.y % 360;
            if (Mathf.Abs(euler.y) > 180f)
            {
                if (euler.y < 0)
                {
                    euler.y += 360f;
                }
                else
                {
                    euler.y -= 360f;
                }
            }
            euler.z = euler.z % 360;
            if (Mathf.Abs(euler.z) > 180f)
            {
                if (euler.z < 0)
                {
                    euler.z += 360f;
                }
                else
                {
                    euler.z -= 360f;
                }
            }
        }

        #endregion

        #region DoScale

        public static SingleAnim DoLocalScale(this Transform obj,
            Vector3 target_value, float time, TimerType timer_type = TimerType.Fixed)
        {
            MotionData motion_data = new MotionData();
            motion_data.start = obj.localScale;
            motion_data.offset = target_value - motion_data.start;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => { motion_data.start = obj.localScale; };
            paras.GetData = (p) => {
                obj.localScale = motion_data.start + motion_data.offset * p;
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }

        #endregion

        #region DoAround

        public static SingleAnim DoAround(this Transform obj,
            Vector3 center_pos, float target_angle, float time,
            TimerType timer_type = TimerType.Fixed)
        {
            MotionData motion_data = new MotionData();
            float radius = Vector2.Distance(
                new Vector2(obj.position.x, obj.position.z),
                new Vector2(center_pos.x, center_pos.z));
            motion_data.start.x = Mathf.Asin((obj.position.x - center_pos.x) / radius) * Mathf.Rad2Deg;
            motion_data.offset.x = target_angle - motion_data.start.x;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => {
                radius = Vector2.Distance(
                    new Vector2(obj.position.x, obj.position.z),
                    new Vector2(center_pos.x, center_pos.z));
                motion_data.start.x = Mathf.Asin((obj.position.x - center_pos.x) / radius) * Mathf.Rad2Deg;
            };
            float angled;
            float pos_x;
            float pos_z;
            paras.GetData = (p) => {
                angled = (motion_data.start.x + motion_data.offset.x * p) % 360;
                pos_x = radius * Mathf.Sin(angled * Mathf.Deg2Rad);
                pos_z = radius * Mathf.Cos(angled * Mathf.Deg2Rad);

                AroudUpdate(obj, pos_x, pos_z, center_pos);
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }
        private static void AroudUpdate(Transform obj, float pos_x, float pos_z, Vector3 center_pos)
        {
            obj.position = new Vector3(pos_x + center_pos.x, obj.position.y, pos_z + center_pos.z);
        }
        public static SingleAnim DoLocalAround(this Transform obj,
            float target_angle, float time, TimerType timer_type = TimerType.Fixed)
        {
            MotionData motion_data = new MotionData();
            float radius = new Vector2(obj.localPosition.x, obj.localPosition.z).magnitude;
            motion_data.start.x = Mathf.Asin(obj.localPosition.x / radius) * Mathf.Rad2Deg;
            motion_data.offset.x = target_angle - motion_data.start.x;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => {
                radius = new Vector2(obj.localPosition.x, obj.localPosition.z).magnitude;
                motion_data.start.x = Mathf.Asin(obj.localPosition.x / radius) * Mathf.Rad2Deg;
            };
            float angled;
            float pos_x;
            float pos_z;
            paras.GetData = (p) => {
                angled = (motion_data.start.x + motion_data.offset.x * p) % 360;
                pos_x = radius * Mathf.Sin(angled * Mathf.Deg2Rad);
                pos_z = radius * Mathf.Cos(angled * Mathf.Deg2Rad);

                AroudLocalUpdate(obj, pos_x, pos_z);
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }
        private static void AroudLocalUpdate(Transform obj, float pos_x, float pos_z)
        {
            obj.localPosition = new Vector3(pos_x, obj.localPosition.y, pos_z);
        }

        #endregion

        #region DoJump

        public static SingleAnim DoJump(this Transform obj,
            Vector3 target_value, float max_y_offset, float gravity = 9.8f,
            TimerType timer_type = TimerType.Fixed)
        {
            MotionData motion_data = new MotionData();
            motion_data.start = obj.position;
            motion_data.offset = GetPlaneOffset(motion_data.start, target_value);

            Vector3 start = motion_data.start;
            float max_y = (start.y >= target_value.y ? start.y : target_value.y) + max_y_offset;
            float speed_y = Mathf.Sqrt(2 * gravity * (max_y - start.y));
            float down_speed = Mathf.Sqrt(2 * gravity * (max_y - target_value.y));
            float time = (speed_y + down_speed) / gravity;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => { motion_data.start = obj.position; };
            paras.GetData = (p) => {
                obj.position = motion_data.start + motion_data.offset * p +
                Vector3.up * GetCurrentY(speed_y, time * p, -gravity);
            };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }
        private static Vector3 GetPlaneOffset(Vector3 start_pos, Vector3 end_pos)
        {
            return new Vector3(end_pos.x, 0, end_pos.z) - new Vector3(start_pos.x, 0, start_pos.z);
        }
        private static float GetCurrentY(float speed_y, float t, float G)
        {
            return speed_y * t + 0.5f * G * t * t;
        }

        #endregion
    }
}

