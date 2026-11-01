@extends('layouts.app')
@section('titulo', 'Nova despesa')

@section('content')
<h1 class="h3 mb-3">Nova despesa</h1>
<form method="POST" action="{{ route('despesas.store') }}">
  @csrf
  @include('despesas._form')
</form>
@endsection