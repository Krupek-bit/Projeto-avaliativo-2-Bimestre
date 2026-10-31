<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Despesa extends Model
{
    protected $table = 'despesas';

    protected $primaryKey = 'id_despesa';

    public $timestamps = false;

    protected $fillable = [
        'id_veiculo',
        'data_despesa',
        'tipo_despesa',
        'descricao',
        'valor',
    ];

    protected function casts(): array
    {
        return [
            'data_despesa' => 'date',
            'valor' => 'decimal:2',
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