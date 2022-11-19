from edal.utils.getsecret import get_secret_from_keyvault
import click

@click.command()
@click.option('--keyname',default=None)
def cli(keyname):        
    print(get_secret_from_keyvault(keyname,None))

if __name__ == '__main__':
    cli()