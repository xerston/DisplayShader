using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;

public class StreamLoader : MonoBehaviour
{
	private string base_path;
	private void Start()
    {
#if UNITY_EDITOR || UNITY_STANDALONE //如果在编译器或者单机中
        base_path = Application.dataPath + "/StreamingAssets/";
#elif UNITY_IPHONE //在Iphone下
        base_path = Application.dataPath + "/Raw/";
#elif UNITY_ANDROID //在Android下
        base_path = "jar:" + Application.dataPath + "!/assets/";
#endif
    }
    public void LoadOneTexture(Action<Texture2D> SingleLoadHandle, string file_url)
	{
		StartCoroutine(LoadImage(SingleLoadHandle, base_path + file_url));
	}

	private int _all_files_count = 0;
	private int _loaded_files_count = 0;

	public void LoadFolderTextures(Action<Texture2D> SingleLoadHandle, string folder_url)
	{
		List<string> files = new List<string>();
		string[] vs = Directory.GetFiles(base_path + folder_url);
		_all_files_count += vs.Length;
		foreach (string i in vs)
		{
			string tmp = Path.GetExtension(i);
			if (tmp == ".png" || tmp == ".jpg")
			{
				files.Add(i);
			}
		}
		foreach (string file in files)
		{
			StartCoroutine(LoadImage(SingleLoadHandle, file));
		}
	}
	private IEnumerator LoadImage(Action<Texture2D> SingleLoadHandle, string full_path)
	{
		UnityWebRequest request = UnityWebRequest.Get(full_path);
		DownloadHandlerTexture texture_download_handler = new DownloadHandlerTexture(true);
		request.downloadHandler = texture_download_handler;
		yield return request.SendWebRequest();
		if (!request.isNetworkError)
		{
			SingleLoadHandle?.Invoke(texture_download_handler.texture);
		}
		_loaded_files_count++;
		if (_loaded_files_count >= _all_files_count) //所有文件加载完成
		{
			_all_files_count = 0;
			_loaded_files_count = 0;
		}
	}

    public void LoadOneText(Action<String> TextHandle , string file_name)
    {
		LoadText(TextHandle, base_path + file_name);
	}
	private IEnumerator LoadText(Action<String> TextHandle, string full_path)
	{
		UnityWebRequest request = UnityWebRequest.Get(full_path);
		request.SendWebRequest(); //发送读取数据请求
		yield return request.SendWebRequest();
		if (!request.isNetworkError)
		{
			TextHandle?.Invoke(request.downloadHandler.text);
		}
	}
}
