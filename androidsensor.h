#ifndef ANDRIOD_SENSOR_H
#define ANDRIOD_SENSOR_H

// github.com/JRAM0012

#include <android/sensor.h>
// code from https://android.googlesource.com/product/google/common/+/brillo-m7-dev/sensors_example/ndk-example-app.cpp

typedef enum {
    GYROSCOPE     = ASENSOR_TYPE_GYROSCOPE,
    GAMEVECTOR    = ASENSOR_TYPE_GAME_ROTATION_VECTOR
}SensorType;

typedef struct {
    ASensorManager* sensor_manager;    // things needed to setup the sensor
    ASensorEventQueue* sensor_queue;   // things needed to setup the sensor
    int sensor_looper_id;              // things needed to setup the sensor
    const ASensor* sensor;                   // the actual sensor 
    SensorType sensor_type;
    Vector3 value;                     // stores the sensor values
    bool working;
}AndroidSensor;

AndroidSensor InitAndroidSensor(SensorType sensor_type, int sample_period) 
{
// creating a sensor manager
    AndroidSensor sensor;
    sensor.working = false;
    sensor.sensor_manager = ASensorManager_getInstance();
    if(!sensor.sensor_manager)
    {
        TraceLog(LOG_ERROR, "SENSOR: Cannot get a sensor manager instance");
        return sensor;
    }

#ifdef PRINT_AVAILABLE_SENSORS
    ASensorList sensor_list;
    int sensor_count = ASensorManager_getSensorList(sensor.sensor_manager, &sensor_list);
    TraceLog(LOG_INFO, "SENSOR: Found %d sensors", sensor_count);
    for(int i = 0; i < sensor_count; i++)
        TraceLog(LOG_INFO, "SENSOR: Found sensor: %s ", ASensor_getName(sensor_list[i]));
#endif

// queue
    sensor.sensor_queue = ASensorManager_createEventQueue(sensor.sensor_manager, 
                                            ALooper_prepare(ALOOPER_PREPARE_ALLOW_NON_CALLBACKS),
                                            sensor.sensor_looper_id,
                                            NULL, /* no indent */
                                            NULL  /* no call back */
                                            );
    if(!sensor.sensor_queue)
    {
        TraceLog(LOG_ERROR, "SENSOR: Failed to create a sensor event queue");
        return sensor;
    }
    
// actual retriving of sensor stuff
    sensor.sensor = ASensorManager_getDefaultSensor(sensor.sensor_manager, sensor_type);
    sensor.sensor_type = sensor_type;

    if(sensor.sensor == NULL)
    {
        TraceLog(LOG_ERROR, "SENSOR: Cannot find the sensor of this type");
        return sensor;
    }

    ASensorEventQueue_enableSensor(sensor.sensor_queue, sensor.sensor);
    int eventrate = ASensorEventQueue_setEventRate(sensor.sensor_queue, sensor.sensor, sample_period);
    TraceLog(LOG_INFO, "SENSOR: SetEvent rate %s\n", eventrate == 0 ? "was success" : "has failed");

    sensor.working = true;
    return sensor;
}

void UseSensor(AndroidSensor* sensor)
{
    if(!sensor->working)
    {
        TraceLog(LOG_ERROR, "SENSOR: Cannot read from a unsuccessful sensor init");
        return;
    } 
    ASensorEvent event;
    do
    {
        ssize_t s = ASensorEventQueue_getEvents(sensor->sensor_queue, &event, 1);
		if( s <= 0 ) break;
        sensor->value.x = event.vector.v[0];
        sensor->value.y = event.vector.v[1];
        sensor->value.z = event.vector.v[2];
    } while (1);
}

void CloseSensor(AndroidSensor* sensor)
{
    if(ASensorEventQueue_disableSensor(sensor->sensor_queue, sensor->sensor))
    {
        TraceLog(LOG_ERROR, "SENSOR: Failed to disable sensor");
    } else TraceLog(LOG_INFO, "SENSOR: Sensor was disabled successfully");
    if(ASensorManager_destroyEventQueue(sensor->sensor_manager, sensor->sensor_queue))
    {
        TraceLog(LOG_ERROR, "SENSOR: Failed to destory event queue");
    } else TraceLog(LOG_INFO, "SENSOR: Event queue was destroyed successfully");

}

#endif