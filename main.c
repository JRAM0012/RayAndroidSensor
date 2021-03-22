#include <stdlib.h>

#include "raylib.h"
#include "raymath.h"

#include "androidsensor.h"


void DrawAngleGauge(Texture2D angleGauge, int x, int y, float angle, char title[], Color color);

int main(void)
{
    int screenWidth = 720, screenHeight = 1600;

    InitWindow(screenWidth, screenHeight, "Android Sensor");

    Camera camera = { { 0.0f, 0.3f, 15.0f }, { 0.0f, 3.0f, 00.0f }, { 0.0f, 1.0f, 00.0f }, 45.0f, 0 };

    SetCameraMode(camera, CAMERA_FREE);

    Texture2D texture = LoadTexture("resources/modeltexture.png");
    Texture2D texAngleGauge = LoadTexture("resources/angle_gauge.png");

    Model models = LoadModel("resources/model.obj");
    models.materials[0].maps[MAP_DIFFUSE].texture = texture;

    SetTargetFPS(60);

    int circlex = 200, circley = 330;

    AndroidSensor angle       = InitAndroidSensor(GAMEVECTOR, 10000);
    unsigned int frames = 0;
    while (!WindowShouldClose())
    {
        UseSensor(&angle);
        models.transform = MatrixRotateXYZ((Vector3) { DEG2RAD * ( 180.0f * angle.value.x), DEG2RAD * ( 180.0f * angle.value.y), DEG2RAD * ( 180.0f * angle.value.z)});
        BeginDrawing();
        ClearBackground(BLUE);
            BeginMode3D(camera);
                DrawModel(models, (Vector3) { 0.0f, 0.0f, 0.0f }, 1.0f, WHITE);
                DrawGrid(10, 1.0);
            EndMode3D();
            DrawAngleGauge(texAngleGauge, circlex +   0 +   0, circley, ( 180.0f * angle.value.x), "x", RED);
            DrawAngleGauge(texAngleGauge, circlex +   0 + 150, circley, ( 180.0f * angle.value.y), "y", RED);
            DrawAngleGauge(texAngleGauge, circlex + 150 + 150, circley, ( 180.0f * angle.value.z), "z", RED);
            DrawText(TextFormat("X: %.3f", angle.value.x), 100, 160, 30, RED);
            DrawText(TextFormat("Y: %.3f", angle.value.y), 300, 160, 30, RED);
            DrawText(TextFormat("Z: %.3f", angle.value.z), 500, 160, 30, RED);
            DrawText(TextFormat("frames: %d", frames), 40, 560, 20, RED);
        EndDrawing();
        frames++;
        if(IsKeyPressed(KEY_BACK))
            break;
    }
    CloseSensor(&angle);
    UnloadModel(models);
    UnloadTexture(texture);
    UnloadTexture(texAngleGauge);
    CloseWindow();
    exit(EXIT_SUCCESS);
    return 0;
}

// Draw angle gauge controls
void DrawAngleGauge(Texture2D angleGauge, int x, int y, float angle, char title[], Color color)
{
    Rectangle srcRec = { 0, 0, angleGauge.width, angleGauge.height };
    Rectangle dstRec = { x, y, angleGauge.width, angleGauge.height };
    Vector2 origin = { angleGauge.width/2, angleGauge.height/2};
    int textSize = 20;
    DrawTexturePro(angleGauge, srcRec, dstRec, origin, angle, color);
    DrawText(TextFormat("%5.1f", angle), x - MeasureText(TextFormat("%5.1f", angle), textSize) / 2, y + 10, textSize, DARKGRAY);
    DrawText(title, x - MeasureText(title, textSize) / 2, y + 60, textSize, DARKGRAY);
}
