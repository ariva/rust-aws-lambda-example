use serde::{Deserialize, Serialize};

#[cfg(feature = "with-lambda")]
use lambda_runtime::{
    tower::{service_fn, BoxError},
    LambdaEvent,
};

#[cfg(not(feature = "with-lambda"))]
type BoxError = Box<dyn std::error::Error + Send + Sync + 'static>;

#[derive(Deserialize, Debug)]
struct Input {
    name: String,
    test_param: Option<bool>,
}

#[derive(Serialize, Debug)]
struct Output {
    greeting: String,
}

#[cfg(feature = "with-lambda")]
async fn lambda_handler(ev: LambdaEvent<Input>) -> Result<Output, BoxError> {
    let (event, _ctx) = ev.into_parts();
    process_input(event).await
}

async fn process_input(input: Input) -> Result<Output, BoxError> {
    let mut greeting = format!(
        "Hello Rusty Lambda World! Received param name: {}!",
        input.name
    );
    if input.test_param.is_some() {
        greeting = format!("{} And param test was set as {}!", greeting, input.test_param.unwrap_or_default());
    }
    Ok(Output { greeting })
}

#[cfg(feature = "with-lambda")]
#[tokio::main]
async fn main() -> Result<(), BoxError> {
    let service_func = service_fn(lambda_handler);
    lambda_runtime::run(service_func).await?;
    Ok(())
}

#[cfg(not(feature = "with-lambda"))]
#[tokio::main]
async fn main() -> Result<(), BoxError> {
    let input_str = std::env::args().nth(1);
    if input_str.is_none() {
        panic!(
            "you must pass an input parameter as the first argument, and it must be a JSON string"
        );
    }
    let input = serde_json::from_str(&input_str.unwrap())?;
    let output = process_input(input).await?;
    println!("{}", serde_json::to_string(&output)?);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn input_with_test_param_none() {
        let res = process_input(Input {
            name: "test".to_string(),
            test_param: None,
        })
            .await;
        assert_eq!(res.is_ok(), true);
        assert_eq!(
            res.unwrap().greeting,
            "Hello Rusty Lambda World! Received param name: test!"
        );
    }

    #[tokio::test]
    async fn input_with_test_param_false() {
        let res = process_input(Input {
            name: "test".to_string(),
            test_param: Some(false),
        })
        .await;
        assert_eq!(res.is_ok(), true);
        assert_eq!(
            res.unwrap().greeting,
            "Hello Rusty Lambda World! Received param name: test! And param test was set as false!"
        );
    }

    #[tokio::test]
    async fn input_with_test_param_true() {
        let res = process_input(Input {
            name: "test".to_string(),
            test_param: Some(true),
        })
        .await;
        assert_eq!(res.is_ok(), true);
        assert_eq!(
            res.unwrap().greeting,
            "Hello Rusty Lambda World! Received param name: test! And param test was set as true!"
        );
    }
}
