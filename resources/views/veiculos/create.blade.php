@extends('layouts.app')
@section('titulo', 'Novo veículo')

@section('content')
<h1 class="h3 mb-3">Novo veículo</h1>
<form method="POST" action="{{ route('veiculos.store') }}">
  @csrf
  @include('veiculos._form')
</form>
@endsection