<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('email')->unique();
            $table->string('password');
            $table->string('display_name');
            $table->enum('role', ['creator', 'business', 'admin']);
            $table->string('phone')->nullable();
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('creator_profiles', function (Blueprint $table): void {
            $table->uuid('user_id')->primary();
            $table->text('bio')->nullable();
            $table->string('country')->nullable();
            $table->string('city')->nullable();
            $table->string('payout_type')->default('momo');
            $table->string('payout_network')->default('MTN');
            $table->string('payout_number')->nullable();
            $table->unsignedBigInteger('followers')->nullable();
            $table->unsignedBigInteger('avg_views')->nullable();
            $table->decimal('engagement_rate', 5, 2)->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('creator_niches', function (Blueprint $table): void {
            $table->id();
            $table->uuid('user_id');
            $table->string('niche');
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->unique(['user_id', 'niche']);
        });

        Schema::create('creator_handles', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->enum('platform', ['TikTok', 'Instagram', 'YouTube', 'X']);
            $table->string('username');
            $table->string('profile_url');
            $table->boolean('verified')->default(false);
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['user_id', 'platform']);
        });

        Schema::create('business_profiles', function (Blueprint $table): void {
            $table->uuid('user_id')->primary();
            $table->string('company_name');
            $table->string('website')->nullable();
            $table->string('contact_phone')->nullable();
            $table->boolean('verified')->default(false);
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('business_profiles');
        Schema::dropIfExists('creator_handles');
        Schema::dropIfExists('creator_niches');
        Schema::dropIfExists('creator_profiles');
        Schema::dropIfExists('users');
    }
};
