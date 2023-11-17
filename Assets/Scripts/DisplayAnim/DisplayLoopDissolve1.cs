using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Tools.TimerEvent.DoAnim;

public class DisplayLoopDissolve1 : MonoBehaviour
{
    private SequenceAnim anim;
    private void OnEnable()
    {
        Material mate = GetComponent<Renderer>().sharedMaterial;
        mate.SetFloat("_DissolveDegree", 0f);
        mate.SetFloat("_Edge1Percent", 0f);
        anim = ObjectDo.GetSequence().AddInterval(0.2f)
            .AddAnim(ObjectDo.DoFloat(0f, 0.21f, 2.3f, (value) => {
                mate.SetFloat("_DissolveDegree", value);
            })).AddAnim(ObjectDo.DoFloat(0f, 0.15f, 2.3f, (value) => {
                mate.SetFloat("_Edge1Percent", value);
            }));
        anim.Start();
    }

    private void OnDisable()
    {
        anim.KillAnim();
        anim = null;
    }
}
