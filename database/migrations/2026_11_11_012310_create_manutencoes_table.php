<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('manutencoes')) {
            return;
        }

        Schema::create('manutencoes', function (Blueprint $table): void {
            $table->increments('id_manutencao');
            $table->unsignedInteger('id_veiculo');
            $table->date('data_manutencao');
            $table->string('tipo_manutencao', 50);
            $table->string('descricao', 255);
            $table->string('oficina', 100)->nullable();
            $table->decimal('valor', 10, 2);
            $table->integer('quilometragem');
            $table->foreign('id_veiculo')->references('id_veiculo')->on('veiculos');
            $table->index('id_veiculo', 'idx_manutencoes_id_veiculo');
            $table->index(['id_veiculo', 'data_manutencao'], 'idx_manutencoes_veiculo_data');
        });
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'sqlite') {
            Schema::dropIfExists('manutencoes');
        }
    }
};
