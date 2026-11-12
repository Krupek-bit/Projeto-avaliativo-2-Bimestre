<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('abastecimentos')) {
            return;
        }

        Schema::create('abastecimentos', function (Blueprint $table): void {
            $table->increments('id_abastecimento');
            $table->unsignedInteger('id_veiculo');
            $table->date('data_abastecimento');
            $table->string('tipo_combustivel', 30);
            $table->decimal('litros', 10, 2);
            $table->decimal('valor_litro', 10, 2);
            $table->decimal('valor_total', 10, 2);
            $table->integer('quilometragem');
            $table->foreign('id_veiculo')->references('id_veiculo')->on('veiculos');
            $table->index('id_veiculo', 'idx_abastecimentos_id_veiculo');
            $table->index(['id_veiculo', 'data_abastecimento'], 'idx_abastecimentos_veiculo_data');
        });
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'sqlite') {
            Schema::dropIfExists('abastecimentos');
        }
    }
};
