<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('modalidade')) {
            return;
        }

        Schema::create('modalidade', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('nome', 100);
            $table->string('descricao', 255)->nullable();
        });
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'sqlite') {
            Schema::dropIfExists('modalidade');
        }
    }
};
