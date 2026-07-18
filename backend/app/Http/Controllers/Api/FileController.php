<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\File;
use Throwable;

class FileController extends Controller
{
    public function show(string $path): Response
    {
        $cleanPath = trim($path, '/');
        if ($cleanPath === '' || str_contains($cleanPath, '..')) {
            abort(404);
        }

        $candidateRoots = array_filter([
            env('FILES_PUBLIC_ROOT'),
            storage_path('app/public'),
        ]);

        foreach ($candidateRoots as $root) {
            $rootPath = rtrim($root, DIRECTORY_SEPARATOR);
            $fullPath = $rootPath.DIRECTORY_SEPARATOR.$cleanPath;

            if (!File::exists($fullPath) || !File::isFile($fullPath)) {
                continue;
            }

            $contents = @file_get_contents($fullPath);
            if ($contents === false) {
                continue;
            }

            $mimeType = 'application/octet-stream';
            try {
                $detected = File::mimeType($fullPath);
                if (is_string($detected) && $detected !== '') {
                    $mimeType = $detected;
                }
            } catch (Throwable) {
                // Fall back to application/octet-stream when mime detection fails.
            }

            return response($contents, 200, [
                'Content-Type' => $mimeType,
                'Cache-Control' => 'public, max-age=31536000, immutable',
            ]);
        }

        abort(404);
    }
}
