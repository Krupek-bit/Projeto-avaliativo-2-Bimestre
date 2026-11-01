@extends('layouts.app')
@section('titulo', 'Editar despesa')

@section('content')
<h1 class="h3 mb-3">Editar despesa</h1>
<form method="POST" action="{{ route('despesas.update', $despesa) }}">
  @csrf
  @method('PUT')
  @include('despesas._form')
</form>
@endsection