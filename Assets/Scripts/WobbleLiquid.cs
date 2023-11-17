using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class WobbleLiquid : MonoBehaviour
{
    public float recover_speed = 1;
    public float wobble_speed = 1;
    public float move_factor = 1;
    public float angle_factor = 0.1f;

    private MeshRenderer _renderer;
    private Material _material;
    private Vector3 _last_pos;
    private Vector3 _last_euler;
    private void Start()
    {
        _renderer = GetComponent<MeshRenderer>();
        _material = _renderer.sharedMaterial;
        _last_pos = transform.position;
        _last_euler = transform.eulerAngles;
        NormalizeEuler(ref _last_euler);
    }

    private float _move_speed;
    private float _angle_speed;
    private float _last_move_speed;
    private float _last_angle_speed;
    private float _time = 0;
    private Vector2 _max_height;
    private Vector2 _current_height;
    private void Update()
    {
        Vector3 velocity = (transform.position - _last_pos) / Time.deltaTime;
        Vector3 euler = transform.eulerAngles;
        NormalizeEuler(ref euler);
        
        Vector3 angle_velocity = (euler - _last_euler) / Time.deltaTime;
        _last_pos = transform.position;
        _last_euler = euler;
        _move_speed = velocity.magnitude;
        _angle_speed = angle_velocity.magnitude;
        if (CheckAccelerate())
        {
            _time = 0.25f / wobble_speed; //使下面的Sin的初始位置是π/4
            _max_height = Vector2.Lerp(_max_height, GetAmplitude(velocity, angle_velocity), 0.8f);
        }
        _last_move_speed = _move_speed;
        _last_angle_speed = _angle_speed;
        
        _current_height = Vector2.Lerp(_max_height, Vector2.zero, _time * recover_speed);
        if (_move_speed == 0 && _angle_speed == 0)
        {
            float percent = Mathf.Sin(Mathf.PI * 2 * _time * wobble_speed);
            _current_height *= percent;
            _time += Time.deltaTime;
        }

        _material.SetFloat("_WobbleX", _current_height.x);
        _material.SetFloat("_WobbleZ", _current_height.y);
    }
    private bool CheckAccelerate()
    {
        if (_move_speed > _last_move_speed || _angle_speed > _last_angle_speed) return true;
        if (_move_speed == _last_move_speed && _last_move_speed != 0) return true;
        if (_angle_speed == _last_angle_speed && _last_angle_speed != 0) return true;
        return false;
    }
    private Vector2 GetAmplitude(Vector3 velocity, Vector3 angle_velocity)
    {
        return new Vector2(velocity.x * -move_factor + angle_velocity.z * angle_factor,
            velocity.z * -move_factor + angle_velocity.x * -angle_factor) * 0.04f;//注意正负号
    }

    private void NormalizeEuler(ref Vector3 euler)
    {
        if (euler.x > 180f) euler.x = (euler.x - 360f) % 360;
        if (euler.y > 180f) euler.y = (euler.y - 360f) % 360;
        if (euler.z > 180f) euler.z = (euler.z - 360f) % 360;
    }
}
