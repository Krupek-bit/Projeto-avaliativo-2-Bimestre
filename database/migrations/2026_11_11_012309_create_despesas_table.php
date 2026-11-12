<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('despesas')) {
            return;
        }

        Schema::create('despesas', function (Blueprint $table): void {
            $table->increments('id_despesa');
            $table->unsignedInteger('id_veiculo');
            $table->date('data_despesa');
            $table->string('tipo_despesa', 50);
            $table->string('descricao', 255)->nullable();
            $table->decimal('valor', 10, 2);
            $table->foreign('id_veiculo')->references('id_veiculo')->on('veiculos');
            $table->index('id_veiculo', 'idx_despesas_id_veiculo');
        });
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'sqlite') {
            Schema::dropIfExists('despesas');
        }
    }
};
