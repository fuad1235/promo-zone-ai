<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('wallets', function (Blueprint $table): void {
            $table->uuid('user_id')->primary();
            $table->enum('role', ['creator', 'business', 'admin']);
            $table->unsignedBigInteger('available_balance')->default(0);
            $table->unsignedBigInteger('held_balance')->default(0);
            $table->unsignedBigInteger('version')->default(0);
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('holds', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->uuid('creator_id');
            $table->uuid('campaign_id');
            $table->uuid('application_id');
            $table->unsignedInteger('amount');
            $table->enum('status', ['active', 'released', 'refunded'])->default('active');
            $table->timestamps();

            $table->foreign('business_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('creator_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('campaign_id')->references('id')->on('campaigns')->cascadeOnDelete();
            $table->foreign('application_id')->references('id')->on('applications')->cascadeOnDelete();
            $table->index(['business_id', 'status']);
        });

        Schema::create('wallet_ledger', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('wallet_user_id');
            $table->enum('type', ['deposit', 'hold', 'release', 'payout', 'refund', 'adjustment']);
            $table->unsignedInteger('amount');
            $table->enum('direction', ['in', 'out']);
            $table->enum('status', ['pending', 'posted', 'failed'])->default('posted');
            $table->uuid('campaign_id')->nullable();
            $table->uuid('application_id')->nullable();
            $table->uuid('hold_id')->nullable();
            $table->timestamps();

            $table->foreign('wallet_user_id')->references('user_id')->on('wallets')->cascadeOnDelete();
            $table->foreign('campaign_id')->references('id')->on('campaigns')->nullOnDelete();
            $table->foreign('application_id')->references('id')->on('applications')->nullOnDelete();
            $table->foreign('hold_id')->references('id')->on('holds')->nullOnDelete();
            $table->index(['wallet_user_id', 'created_at']);
        });

        Schema::create('withdraw_requests', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('creator_id');
            $table->unsignedInteger('amount');
            $table->string('payout_type')->default('momo');
            $table->string('network')->default('MTN');
            $table->string('number');
            $table->enum('status', ['pending', 'approved', 'rejected', 'paid'])->default('pending');
            $table->timestamps();

            $table->foreign('creator_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['creator_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('withdraw_requests');
        Schema::dropIfExists('wallet_ledger');
        Schema::dropIfExists('holds');
        Schema::dropIfExists('wallets');
    }
};
