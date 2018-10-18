// Alternate music mod for 2004 Cave Story
// Copyright © 2018 Clownacy

#include "vorbisfile.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>

#include <vorbis/vorbisfile.h>

#include "common.h"
#include "memory_file.h"

typedef struct DecoderData_Vorbisfile
{
	unsigned char *file_buffer;
	size_t file_size;
	bool loops;
} DecoderData_Vorbisfile;

typedef struct Decoder_Vorbisfile
{
	DecoderData_Vorbisfile *data;
	OggVorbis_File vorbis_file;
	unsigned int channel_count;
} Decoder_Vorbisfile;

static size_t MemoryFile_fread_wrapper(void *output, size_t size, size_t count, void *file)
{
	return MemoryFile_fread(output, size, count, file);
}

static int MemoryFile_fseek_wrapper(void *file, ogg_int64_t offset, int origin)
{
	return MemoryFile_fseek(file, offset, origin);
}

static int MemoryFile_fclose_wrapper(void *file)
{
	return MemoryFile_fclose(file);
}

static long MemoryFile_ftell_wrapper(void *file)
{
	return MemoryFile_ftell(file);
}

static const ov_callbacks ov_callback_memory = {
	MemoryFile_fread_wrapper,
	MemoryFile_fseek_wrapper,
	MemoryFile_fclose_wrapper,
	MemoryFile_ftell_wrapper
};

DecoderData_Vorbisfile* Decoder_Vorbisfile_LoadData(const char *file_path, bool loops, LinkedBackend *linked_backend)
{
	(void)linked_backend;

	DecoderData_Vorbisfile *data = NULL;

	size_t file_size;
	unsigned char *file_buffer = MemoryFile_fopen_to(file_path, &file_size);

	if (file_buffer)
	{
		data = malloc(sizeof(DecoderData_Vorbisfile));
		data->file_buffer = file_buffer;
		data->file_size = file_size;
		data->loops = loops;
	}

	return data;
}

void Decoder_Vorbisfile_UnloadData(DecoderData_Vorbisfile *data)
{
	if (data)
	{
		free(data->file_buffer);
		free(data);
	}
}

Decoder_Vorbisfile* Decoder_Vorbisfile_Create(DecoderData_Vorbisfile *data, DecoderInfo *info)
{
	Decoder_Vorbisfile *this = NULL;

	if (data && data->file_buffer)
	{
		MemoryFile *memory_file = MemoryFile_fopen_from(data->file_buffer, data->file_size, false);

		OggVorbis_File vorbis_file;

		if (ov_open_callbacks(memory_file, &vorbis_file, NULL, 0, ov_callback_memory) == 0)
		{
			this = malloc(sizeof(Decoder_Vorbisfile));

			vorbis_info *v_info = ov_info(&vorbis_file, -1);

			this->vorbis_file = vorbis_file;
			this->channel_count = v_info->channels;
			this->data = data;

			info->sample_rate = v_info->rate;
			info->channel_count = v_info->channels;
			info->decoded_size = ov_pcm_total(&vorbis_file, -1) * v_info->channels * sizeof(float);
			info->format = DECODER_FORMAT_F32;
		}
		else
		{
			MemoryFile_fclose(memory_file);
		}
	}

	return this;
}

void Decoder_Vorbisfile_Destroy(Decoder_Vorbisfile *this)
{
	if (this)
	{
		ov_clear(&this->vorbis_file);
		free(this);
	}
}

void Decoder_Vorbisfile_Rewind(Decoder_Vorbisfile *this)
{
	ov_time_seek(&this->vorbis_file, 0);
}

static unsigned long ReadFloats(Decoder_Vorbisfile *this, float *buffer, unsigned long frames_to_do)
{
	float **float_buffer;
	long frames_read = ov_read_float(&this->vorbis_file, &float_buffer, frames_to_do, NULL);

	for (long i = 0; i < frames_read; ++i)
		for (unsigned int j = 0; j < this->channel_count; ++j)
			*buffer++ = float_buffer[j][i];

	return frames_read;
}

unsigned long Decoder_Vorbisfile_GetSamples(Decoder_Vorbisfile *this, void *buffer_void, unsigned long frames_to_do)
{
	float *buffer = buffer_void;

	unsigned long frames_done_total = 0;

	for (unsigned long frames_done; frames_done_total != frames_to_do; frames_done_total += frames_done)
	{
		frames_done = ReadFloats(this, buffer + (frames_done_total * this->channel_count), frames_to_do - frames_done_total);

		if (frames_done == 0)
		{
			if (this->data->loops)
				Decoder_Vorbisfile_Rewind(this);
			else
				break;
		}
	}


	return frames_done_total;
}
