using System;
using UnityEngine;

public class GameObserver
{
	public static void Init()
	{

	}

	public static event Action ManagersResetHandle;

	public static void PoolsReset()
	{
		ManagersResetHandle?.Invoke();
	}

	public static event Action GeneralHandle = null;

	public static void UseGeneralHandle()
	{
		GeneralHandle?.Invoke();
		GeneralHandle = null;
	}
}
