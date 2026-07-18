<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('campaigns', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->string('title');
            $table->text('description');
            $table->string('platform');
            $table->unsignedInteger('target_views');
            $table->unsignedInteger('payout_amount_ghs');
            $table->unsignedInteger('creators_needed')->default(1);
            $table->string('mention')->nullable();
            $table->text('do_dont');
            $table->dateTime('start_date');
            $table->dateTime('end_date');
            $table->enum('status', ['draft', 'published', 'closed'])->default('draft');
            $table->unsignedInteger('applicants_count')->default(0);
            $table->unsignedInteger('approved_count')->default(0);
            $table->timestamps();

            $table->foreign('business_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['status', 'platform', 'payout_amount_ghs']);
        });

        Schema::create('campaign_hashtags', function (Blueprint $table): void {
            $table->id();
            $table->uuid('campaign_id');
            $table->string('hashtag');
            $table->timestamps();

            $table->foreign('campaign_id')->references('id')->on('campaigns')->cascadeOnDelete();
            $table->unique(['campaign_id', 'hashtag']);
        });

        Schema::create('campaign_media', function (Blueprint $table): void {
            $table->id();
            $table->uuid('campaign_id');
            $table->string('url');
            $table->timestamps();

            $table->foreign('campaign_id')->references('id')->on('campaigns')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('campaign_media');
        Schema::dropIfExists('campaign_hashtags');
        Schema::dropIfExists('campaigns');
    }
};
