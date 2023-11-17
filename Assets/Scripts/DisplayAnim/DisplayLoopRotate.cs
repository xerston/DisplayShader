using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Tools.TimerEvent.DoAnim;

public class DisplayLoopRotate : MonoBehaviour
{
    private SequenceAnim anim;
    public float animTime = 2.5f;
    private void OnEnable()
    {
        Vector3 target = transform.localEulerAngles + new Vector3(0f, 0f, 180f);
        SingleAnim singleAnim = transform.DoLocalRotate(target, animTime).SetLoop(0, LoopType.Increase)
            .SetEaseType(EaseType.Linear);
        anim = ObjectDo.GetSequence().AddInterval(0.2f).AddAnim(singleAnim);
        anim.Start();
    }

    private void OnDisable()
    {
        anim.KillAnim();
        anim = null;
    }
}
