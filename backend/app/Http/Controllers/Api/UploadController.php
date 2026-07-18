<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class UploadController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        if (!$request->hasFile('file')) {
            return response()->json([
                'message' => 'No file received. Check file size and server upload limits (upload_max_filesize, post_max_size).',
            ], 422);
        }

        $request->validate(
            [
                'file' => ['required', 'file', 'max:51200'],
                'folder' => ['nullable', 'string', 'max:120'],
            ],
            [
                'file.required' => 'No file payload received by backend.',
                'file.file' => 'Uploaded payload is not a valid file.',
                'file.max' => 'File is too large. Maximum allowed size is 50MB.',
                'folder.max' => 'Target folder path is too long.',
            ]
        );

        $folder = trim($request->input('folder', 'uploads'), '/');
        $path = $request->file('file')->store($folder, 'public');
        $encodedPath = implode('/', array_map('rawurlencode', explode('/', $path)));
        $url = rtrim($request->getSchemeAndHttpHost(), '/').'/api/files/'.$encodedPath;

        return response()->json(['url' => $url], 201);
    }
}
