<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('historico_status_veiculo')) {
            return;
        }

        Schema::create('historico_status_veiculo', function (Blueprint $table): void {
            $table->increments('id_historico');
            $table->unsignedInteger('id_veiculo');
            $table->string('status_anterior', 20)->nullable();
            $table->string('status_novo', 20);
            $table->timestamp('data_alteracao')->useCurrent();
            $table->foreign('id_veiculo')->references('id_veiculo')->on('veiculos');
            $table->index(['id_veiculo', 'data_alteracao'], 'idx_hist_status_veiculo_data');
        });
    }

    public function down(): void
    {
        if (DB::connection()->getDriverName() === 'sqlite') {
            Schema::dropIfExists('historico_status_veiculo');
        }
    }
};
