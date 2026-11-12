<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('viagens')) {
            return;
        }

        Schema::create('viagens', function (Blueprint $table): void {
            $table->increments('id_viagem');
            $table->unsignedInteger('id_veiculo');
            $table->unsignedInteger('id_motorista');
            $table->timestamp('data_saida');
            $table->timestamp('data_retorno')->nullable();
            $table->integer('km_inicial');
            $table->integer('km_final')->nullable();
            $table->string('destino', 100);
            $table->string('finalidade', 255)->nullable();
            $table->uuid('id_modalidade')->nullable();
            $table->foreign('id_veiculo')->references('id_veiculo')->on('veiculos');
            $table->foreign('id_motorista')->references('id_motorista')->on('motoristas');
            $table->foreign('id_modalidade')->references('id')->on('modalidade');
            $table->index('id_modalidade', 'idx_viagens_id_modalidade');
        });
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'sqlite') {
            Schema::dropIfExists('viagens');
        }
    }
};
