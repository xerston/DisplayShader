using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Tools.TimerEvent.DoAnim;

public class DisplayLoopMove : MonoBehaviour
{
    private SequenceAnim anim;
    private void OnEnable()
    {
        Vector3 target = transform.position + new Vector3(5f, 0f, 0f);
        SingleAnim singleAnim = transform.DoMove(target, 1f)
            .SetEaseType(EaseType.SinIn);
        anim = ObjectDo.GetSequence().AddInterval(0.2f).AddAnim(singleAnim);
        anim.Start();
    }

    private void OnDisable()
    {
        anim.KillAnim();
        anim = null;
    }
}
