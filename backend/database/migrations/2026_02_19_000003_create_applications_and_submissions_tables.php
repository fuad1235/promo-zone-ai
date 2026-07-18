<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('applications', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('campaign_id');
            $table->uuid('business_id');
            $table->uuid('creator_id');
            $table->uuid('creator_handle_id')->nullable();
            $table->enum('status', [
                'applied',
                'approved_by_business',
                'rejected',
                'sample_submitted',
                'sample_approved',
                'sample_rejected',
                'posted',
                'proof_submitted',
                'proof_approved',
                'proof_rejected',
                'paid',
            ])->default('applied');
            $table->uuid('hold_id')->nullable();

            $table->dateTime('applied_at')->nullable();
            $table->dateTime('approved_at')->nullable();
            $table->dateTime('sample_submitted_at')->nullable();
            $table->dateTime('sample_approved_at')->nullable();
            $table->dateTime('posted_at')->nullable();
            $table->dateTime('proof_submitted_at')->nullable();
            $table->dateTime('proof_approved_at')->nullable();
            $table->dateTime('paid_at')->nullable();
            $table->text('reviewer_message')->nullable();
            $table->timestamps();

            $table->foreign('campaign_id')->references('id')->on('campaigns')->cascadeOnDelete();
            $table->foreign('business_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('creator_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('creator_handle_id')->references('id')->on('creator_handles')->nullOnDelete();
            $table->unique(['campaign_id', 'creator_id']);
            $table->index(['creator_id', 'status']);
            $table->index(['business_id', 'campaign_id', 'status']);
        });

        Schema::create('submissions', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('application_id');
            $table->enum('type', ['sample', 'proof']);
            $table->text('message')->nullable();
            $table->string('post_url')->nullable();
            $table->unsignedInteger('declared_views')->nullable();
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->text('reviewer_message')->nullable();
            $table->timestamps();

            $table->foreign('application_id')->references('id')->on('applications')->cascadeOnDelete();
            $table->index(['application_id', 'type', 'created_at']);
        });

        Schema::create('submission_media', function (Blueprint $table): void {
            $table->id();
            $table->uuid('submission_id');
            $table->enum('media_kind', ['media', 'screenshot']);
            $table->string('url');
            $table->timestamps();

            $table->foreign('submission_id')->references('id')->on('submissions')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('submission_media');
        Schema::dropIfExists('submissions');
        Schema::dropIfExists('applications');
    }
};
