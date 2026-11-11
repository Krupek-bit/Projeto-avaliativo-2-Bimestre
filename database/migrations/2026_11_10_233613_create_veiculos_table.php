<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // A tabela já existe no PostgreSQL/Neon.
        // Nesse caso, não precisamos recriá-la.
        if (Schema::hasTable('veiculos')) {
            return;
        }

        Schema::create('veiculos', function (Blueprint $table) {
            $table->increments('id_veiculo');

            $table->string('placa', 10)->unique();
            $table->string('marca', 50);
            $table->string('modelo', 50);
            $table->integer('ano');
            $table->string('tipo', 30);
            $table->decimal('capacidade', 10, 2)->nullable();
            $table->string('status', 20);
            $table->integer('quilometragem_atual')->default(0);

            $table->index('status', 'idx_veiculos_status');
        });
    }

    public function down(): void
    {
        // A tabela existente no Neon não pertence a esta migration.
        // Só removemos a tabela criada no SQLite de testes.
        if (DB::connection()->getDriverName() === 'sqlite') {
            Schema::dropIfExists('veiculos');
        }
    }
};
