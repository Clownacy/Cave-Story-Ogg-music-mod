// Ogg music mod for Freeware Cave Story
// Copyright © 2018 Clownacy

#include "backend.h"

#include <stdbool.h>
#include <stddef.h>
#include <string.h>
#include <windows.h>

#include <SDL2/SDL.h>

#include "mod_loader.h"

typedef struct BackendStream
{
	SDL_AudioDeviceID device;
	unsigned int volume;
	unsigned int channel_count;
} BackendStream;

static long int(*UserDataCallback)(void*, long);

static void DataCallbackWrapper(void *user_data, unsigned char *output_buffer, int bytes_to_do)
{
	BackendStream *stream = (BackendStream*)user_data;

	const unsigned int bytes_per_sample = stream->channel_count * 2;

	long bytes_done = UserDataCallback(output_buffer, bytes_to_do / bytes_per_sample) * bytes_per_sample;

	memset(output_buffer + bytes_done, 0, bytes_to_do - bytes_done);

	short *output_buffer_short = (short*)output_buffer;
	for (int i = 0; i < bytes_to_do / 2; ++i)
	{
		short sample = (*output_buffer_short * stream->volume) / 0x100;
		*output_buffer_short++ = sample;
	}
}

bool Backend_Init(long int(*callback)(void*, long))
{
	SDL_Init(SDL_INIT_AUDIO);

	UserDataCallback = callback;

	return true;
}

BackendStream* Backend_CreateStream(unsigned int sample_rate, unsigned int channel_count)
{
	BackendStream *stream = malloc(sizeof(BackendStream));

	SDL_AudioSpec want;
	SDL_AudioDeviceID device;

	memset(&want, 0, sizeof(want));
	want.freq = sample_rate;
	want.format = AUDIO_S16;
	want.channels = channel_count;
	want.samples = 4096;
	want.callback = DataCallbackWrapper;
	want.userdata = stream;

	device = SDL_OpenAudioDevice(NULL, 0, &want, NULL, 0);
	if (device)
	{
		stream->device = device;
		stream->channel_count = channel_count;
		stream->volume = 0x100;
	}
	else
	{
		free(stream);
		stream = NULL;
	}

	return stream;
}

bool Backend_DestroyStream(BackendStream *stream)
{
	bool success = false;

	if (stream)
	{
		SDL_CloseAudioDevice(stream->device);

		success = true;
	}

	return success;
}

void Backend_SetVolume(BackendStream *stream, float volume)
{
	if (stream)
		stream->volume = volume * 0x100;
}

bool Backend_PauseStream(BackendStream *stream)
{
	if (stream)
	{
		SDL_PauseAudioDevice(stream->device, -1);
	}

	return true;
}

bool Backend_ResumeStream(BackendStream *stream)
{
	if (stream)
	{
		SDL_PauseAudioDevice(stream->device, 0);
	}

	return true;
}
