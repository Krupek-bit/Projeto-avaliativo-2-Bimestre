<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Manutencao extends Model
{
    protected $table = 'manutencoes';

    protected $primaryKey = 'id_manutencao';

    public $timestamps = false;

    protected $fillable = [
        'id_veiculo',
        'data_manutencao',
        'tipo_manutencao',
        'descricao',
        'oficina',
        'valor',
        'quilometragem',
    ];

    protected function casts(): array
    {
        return [
            'data_manutencao' => 'date',
            'valor' => 'decimal:2',
            'quilometragem' => 'integer',
        ];
    }

    public function veiculo(): BelongsTo
    {
        return $this->belongsTo(
            Veiculo::class,
            'id_veiculo',
            'id_veiculo'
        );
    }
}
