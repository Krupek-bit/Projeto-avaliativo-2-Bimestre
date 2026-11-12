<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('hodometros')) {
            return;
        }

        Schema::create('hodometros', function (Blueprint $table): void {
            $table->increments('id_hodometro');
            $table->unsignedInteger('id_veiculo');
            $table->date('data_registro');
            $table->integer('quilometragem');
            $table->string('observacao', 255)->nullable();
            $table->foreign('id_veiculo')->references('id_veiculo')->on('veiculos');
            $table->index('id_veiculo', 'idx_hodometros_id_veiculo');
        });
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'sqlite') {
            Schema::dropIfExists('hodometros');
        }
    }
};
