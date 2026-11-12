<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('motoristas')) {
            return;
        }

        Schema::create('motoristas', function (Blueprint $table): void {
            $table->increments('id_motorista');
            $table->string('nome', 100);
            $table->string('cnh', 20)->unique();
            $table->string('categoria_cnh', 5);
            $table->string('telefone', 20)->nullable();
            $table->date('data_admissao');
            $table->string('status', 20);
            $table->date('validade_cnh')->nullable();
            $table->index('status', 'idx_motoristas_status');
        });
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'sqlite') {
            Schema::dropIfExists('motoristas');
        }
    }
};
