<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('api_idempotency_keys', function (Blueprint $table): void {
            $table->id();
            $table->string('key_hash', 64)->unique();
            $table->uuid('user_id')->nullable()->index();
            $table->string('method', 10);
            $table->string('path', 255);
            $table->string('status', 20)->default('processing');
            $table->unsignedSmallInteger('response_status')->nullable();
            $table->longText('response_body')->nullable();
            $table->json('response_headers')->nullable();
            $table->dateTime('locked_until')->nullable();
            $table->dateTime('expires_at')->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('api_idempotency_keys');
    }
};
